import { Principal } from '@dfinity/principal';
import { resolve } from 'node:path';

import { Actor, PocketIc, createIdentity } from '@hadronous/pic';
import { IDL } from '@dfinity/candid';
import {
    _SERVICE as ChronoService, idlFactory as ChronoIdlFactory, init as ChronoInit,
} from './build/router.idl.js';

import {
    _SERVICE as SliceService, idlFactory as SliceIdlFactory, init as SliceInit,
} from './build/slice.idl.js';

import {
    _SERVICE as ClientService, idlFactory as ChronoClientIdlFactory, init as ChronoClientInit,
} from './build/client.idl.js';


import { InsertReq, QueryResp } from "./build/slice.idl";

//@ts-ignore
import { toState } from "@infu/icblast";
import { AccountIdentifier, SubAccount } from "@dfinity/ledger-icp"
import util from 'util';
const WASM_ROUTER_PATH = resolve(__dirname, "./build/router.wasm");
const WASM_CLIENT_PATH = resolve(__dirname, "./build/client.wasm");


export async function ChronoCan(pic: PocketIc) {

    const fixture = await pic.setupCanister<ChronoService>({
        idlFactory: ChronoIdlFactory,
        wasm: WASM_ROUTER_PATH,
        arg: IDL.encode(ChronoInit({ IDL }), []),
    });


    return fixture;
};


export async function ChronoClientCan(pic: PocketIc, router: Principal) {

    const fixture = await pic.setupCanister<ClientService>({
        idlFactory: ChronoClientIdlFactory,
        wasm: WASM_CLIENT_PATH,
        arg: IDL.encode(ChronoClientInit({ IDL }), [{ router }]),
    });


    return fixture;
};


export function DF() {

    return {
        pic: undefined as PocketIc,
        chrono: undefined as Actor<ChronoService>,
        client: undefined as Actor<ClientService>,
        chronoCanisterId: undefined as Principal,
        clientCanisterId: undefined as Principal,

        jo: undefined as ReturnType<typeof createIdentity>,

        toState: toState,

        inspect(obj: any): void {
            console.log(util.inspect(toState(obj), { depth: null, colors: true }));
        },
        async passTime(n: number): Promise<void> {
            n = n * 2;
            if (!this.pic) throw new Error('PocketIc is not initialized');
            for (let i = 0; i < n; i++) {
                await this.pic.advanceTime(3 * 1000);
                await this.pic.tick(6);
            }
        },
        async passTimeMinute(n: number): Promise<void> {
            if (!this.pic) throw new Error('PocketIc is not initialized');
            await this.pic.advanceTime(n * 60 * 1000);
            await this.pic.tick(3);
            // await this.passTime(5)
        },
        tid(time: number, id: number): bigint {
            return BigInt(time) << BigInt(32) | BigInt(id);
        },
        async insert(req: InsertReq): Promise<void> {

            let get_slices = await this.chrono.get_slices();


            let v_type = Object.keys(req.data)[0];

            type DataInSlices = { [canister_id: string]: InsertReq };
            let data_inslices: DataInSlices = {};


            //@ts-ignore
            for (let d of req.data[v_type]) {
                let [tid, value] = d;
                let [time, id] = [Number(tid >> BigInt(32)), Number(tid & BigInt(0xffffffff))];

                let slice = get_slices.find((s) => s[1] <= time && s[2] > time);
                if (!slice) throw new Error(`Slice not found for time ${time}`);

                const canisterId = slice[0].toText();


                if (!data_inslices[canisterId]) data_inslices[canisterId] = {
                    path: req.path,
                    //@ts-ignore
                    data: { [v_type]: [] }
                };

                //@ts-ignore
                data_inslices[canisterId].data[v_type].push([tid, value]);

            }


            for (let canisterId in data_inslices) {
                let slice = this.pic.createActor<SliceService>(SliceIdlFactory, Principal.fromText(canisterId));
                slice.setIdentity(this.jo);
                await slice.chrono_command([{ insert: [data_inslices[canisterId]] }]);
            }


        },


        async read(req: { from: bigint, to: bigint, path: string }): Promise<QueryResp> {
            let get_slices = await this.chrono.get_slices();

            let [from_time] = [Number(req.from >> BigInt(32)), Number(req.from & BigInt(0xffffffff))];
            let [to_time] = [Number(req.to >> BigInt(32)), Number(req.to & BigInt(0xffffffff))];

            // Find slices within the time range
            let relevantSlices = get_slices.filter(
                (s) => s[1] <= Number(to_time) && s[2] > Number(from_time)
            );

            if (relevantSlices.length === 0) {
                throw new Error(`No slices found for the time range ${from_time} to ${to_time}`);
            }

            let queries = relevantSlices.map((slice) => {
                const canisterId = slice[0].toText();
                return {
                    canisterId,
                    queryReq: {
                        search: [{
                            path: { exact: req.path },
                            direction: { fwd: null }, // Assuming forward query; adjust as needed
                            limit: 100n, // Arbitrary limit, adjust if required
                            from: req.from,
                        }]
                    }
                };
            });

            let mergedResults: { [key: string]: { [v_type: string]: [string, any][] } } = {};

            for (let query of queries) {
                let slice = this.pic.createActor<SliceService>(
                    SliceIdlFactory,
                    Principal.fromText(query.canisterId)
                );

                let result = await slice.chrono_query([query.queryReq]);

                for (let entry of result) {
                    if (!entry.search[0]) continue;
                    let [path, data] = entry.search[0];
                    if (!mergedResults[path]) {
                        mergedResults[path] = {};
                    }

                    // Dynamically merge all v_types (e.g., FLOAT, INT, etc.)
                    for (let v_type in data) {
                        if (!mergedResults[path][v_type]) {
                            mergedResults[path][v_type] = [];
                        }
                        //@ts-ignore
                        mergedResults[path][v_type].push(...data[v_type]);
                    }
                }
            }

            // Convert mergedResults back into QueryResp format

            let finalResult: QueryResp = {
                //@ts-ignore
                search: Object.entries(mergedResults).map(([path, data]) => [
                    path,
                    data,
                ])
            };

            return finalResult;
        },



        async beforeAll(): Promise<void> {
            this.jo = createIdentity('superSecretAlicePassword');

            // Initialize PocketIc
            this.pic = await PocketIc.create(process.env.PIC_URL);
            const date = Date.now();
            await this.pic.setTime(date);


            const chronoFixture = await ChronoCan(this.pic);
            this.chrono = chronoFixture.actor;
            this.chronoCanisterId = chronoFixture.canisterId;


            await this.pic.addCycles(this.chronoCanisterId, 5000_000_000_000_000);
            // Setup interactions between ledger and pylon

            await this.pic.updateCanisterSettings({ canisterId: this.chronoCanisterId, controllers: [this.jo.getPrincipal()] });
            this.chrono.setIdentity(this.jo);

            await this.chrono.set_access([[this.jo.getPrincipal(), "person/"]]);



            // Advance time to sync with initialization
            await this.passTime(50);
            await this.pic.tick(60)

            const clientFixture = await ChronoClientCan(this.pic, this.chronoCanisterId);
            this.client = clientFixture.actor;
            this.clientCanisterId = clientFixture.canisterId;

            await this.chrono.set_access([[this.clientCanisterId, "person/"]]);

            await this.passTime(50);


        },

        async afterAll(): Promise<void> {
            if (!this.pic) throw new Error('PocketIc is not initialized');
            await this.pic.tearDown();
        },



    };
}


