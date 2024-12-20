import Ver1 "./memory/v1";
import MU "mo:mosup";
import Slice "./canister/slice";
import SliceClass "./slice";
import Principal "mo:base/Principal";
import SWB "mo:swbstable/Stable";
import ErrLog "./errlog";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Vector "mo:vector";
import IC "./services/ic";
import Timer "mo:base/Timer";
import U "./utils";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Map "mo:map/Map";

module {

    let SLICE_CYCLES = 40_000_000_000_000;
    let SLICE_ADDITIONAL_CONTROLLERS : [Principal] = [];
    let SLICE_CYCLES_REFILL_SEC = 21600; // 6 hours

    // 30 days in seconds
    let SLICE_TIMESPAN : Nat32 = 2592000;
    let START_DATE : Nat32 = 1660052760;

    public module Mem {
        public module ChronoRouter {
            public let V1 = Ver1.ChronoRouter;
        };
    };

    public let VM = Mem.ChronoRouter.V1;

    type SliceInitArgs = SliceClass.Mem.ChronoSlice.V1.InitArgs;

    public type CanisterInfo = {
        cycles : Nat;
    };

    public type SetAccessRequest = [(Principal, Text)];

    public type GetSlicesResp = [(Principal, Nat32, Nat32)];

    public class ChronoRouter<system>({
        xmem : MU.MemShell<VM.Mem>;
        me : Principal;
    }) = {

        let mem = MU.access(xmem);

        let NTN_GOV = Principal.fromText("eqsml-lyaaa-aaaaq-aacdq-cai");

        let _eventlog_cls = SWB.SlidingWindowBuffer<Text>(mem.routerlog);
        let _eventlog = ErrLog.ErrLog({
            mem = _eventlog_cls;
        });

        let ic = actor ("aaaaa-aa") : IC.Self;

        public func get_slices() : GetSlicesResp {
            Vector.toArray(Vector.map<VM.SliceCan, (Principal, Nat32, Nat32)>(mem.slices, func x = (x.canister_id, x.slice_from, x.slice_to)));
        };

        public func set_access<system>(caller : Principal, req : SetAccessRequest) : () {
            assert (Principal.isController(caller) or caller == NTN_GOV);
            for ((k, v) in req.vals()) {
                Map.set(mem.access, Map.phash, k, v);
            };

            ignore Timer.setTimer<system>(
                #seconds 1,
                func() : async () {
                    await spread_access();
                },
            );
        };

        private func spread_access() : async () {
            for (slice in Vector.vals(mem.slices)) {
                try {
                    let myActor = actor (Principal.toText(slice.canister_id)) : Slice.Slice;
                    await myActor.chrono_set_access(Map.toArray(mem.access));
                } catch (err) {
                    _eventlog.add("ERR : Failed to spread access " # Error.message(err));
                };
            };
        };

        private func spawn_slices<system>() : async () {

            let now = U.now_sec() + 21600 : Nat32; // 6 hours

            let dur = now - START_DATE;

            let num_slices = dur / SLICE_TIMESPAN + 1;
            let cur_slices = Nat32.fromNat(Vector.size(mem.slices));
            _eventlog.add("OK : Spawning slices " # debug_show ({ now; num_slices; cur_slices }));

            if (num_slices == cur_slices) return;

            // find all the missing ones and create them

            var i : Nat32 = 0;
            label create_missing loop {
                let slice_from = START_DATE + i * SLICE_TIMESPAN;
                let slice_to = slice_from + SLICE_TIMESPAN;

                if (
                    not Option.isNull(
                        Vector.firstIndexWith<VM.SliceCan>(
                            mem.slices,
                            func(s) {
                                s.slice_from == slice_from;
                            },
                        )
                    )
                ) continue create_missing;

                let initArg : SliceInitArgs = {
                    slice_from = slice_from;
                    slice_to = slice_to;
                    router = me;
                };

                let new_actor = await new_slice<system>(initArg);
                let canister_id = Principal.fromActor(new_actor);

                Vector.add(
                    mem.slices,
                    {
                        slice_from = slice_from;
                        slice_to = slice_to;
                        canister_id = canister_id;
                    },
                );

                i += 1;
                if (i >= num_slices) break create_missing;

            };

        };

        private func new_slice<system>(initArg : SliceInitArgs) : async (Slice.Slice) {

            if (ExperimentalCycles.balance() > SLICE_CYCLES * 2) {
                ExperimentalCycles.add<system>(SLICE_CYCLES);
            } else {
                _eventlog.add("ERR : Not enough cycles" # debug_show (ExperimentalCycles.balance()));

                Debug.trap("Not enough cycles" # debug_show (ExperimentalCycles.balance()));
            };
            _eventlog.add("OK : Creating new pair canister " # debug_show (initArg));

            let SliceMgr = (system Slice.Slice)(
                #new {
                    settings = ?{
                        freezing_threshold = ?1296000;
                        controllers = ?Array.append([me], SLICE_ADDITIONAL_CONTROLLERS);
                        memory_allocation = null;
                        compute_allocation = null;
                    };
                }
            );

            try {
                let newactor = (await SliceMgr(initArg));
                _eventlog.add("OK : Pair canister created " # Principal.toText(Principal.fromActor(newactor)));
                await newactor.chrono_set_access(Map.toArray(mem.access));

                return newactor;
            } catch (err) {
                _eventlog.add("ERR : Failed creating pair canister " # Error.message(err));
                Debug.trap("Error creating pair canister " # Error.message(err));
            };

        };

        private func upgrade_slices<system>() : async () {

            for (slice in Vector.vals(mem.slices)) {
                try {
                    let myActor = actor (Principal.toText(slice.canister_id)) : Slice.Slice;
                    let full_args : SliceInitArgs = {
                        slice_from = slice.slice_from;
                        slice_to = slice.slice_to;
                        router = me;
                    };

                    // 1. Stop canister
                    await ic.stop_canister({ canister_id = slice.canister_id });

                    // 2. Upgrade
                    let SliceMgr = (system Slice.Slice)(#upgrade myActor);

                    ignore await SliceMgr(full_args);

                    // 3. Start canister
                    await ic.start_canister({ canister_id = slice.canister_id });

                    _eventlog.add("OK : Successful upgrading of canister " # Principal.toText(slice.canister_id));
                } catch (err) {
                    _eventlog.add("ERR : Failed upgrading canister " # Principal.toText(slice.canister_id) # " : " # Error.message(err));
                };
            };
        };

        // Tops up all pair canisters with cycles
        private func cycle_maintenance<system>() : async () {
            let cans = Vector.toArray(mem.slices);

            for (a in cans.vals()) {

                try {
                    let act = actor (Principal.toText(a.canister_id)) : Slice.Slice;
                    let ci = await act.canister_info();
                    let can_cycles = ci.cycles;

                    if (can_cycles < SLICE_CYCLES / 2) {
                        if (ExperimentalCycles.balance() > SLICE_CYCLES * 2) {
                            let refill_amount = SLICE_CYCLES - can_cycles : Nat;
                            try {
                                ExperimentalCycles.add<system>(refill_amount);
                                await act.deposit_cycles();
                                _eventlog.add("Ok : Refilled " # Principal.toText(a.canister_id) # " with " # debug_show (refill_amount));
                            } catch (err) {
                                _eventlog.add("Err : Failed to refill canister " # Principal.toText(a.canister_id) # " with " # debug_show (refill_amount) # " : " # Error.message(err));
                            };
                        } else {
                            _eventlog.add("Err : Not enough cycles to replenish pair canisters " # debug_show ExperimentalCycles.balance());
                        };
                    };
                } catch (err) {
                    _eventlog.add("Err : Failed to get canister info " # Principal.toText(a.canister_id) # " : " # Error.message(err));
                };
            };
        };

        private func update_slice_settings<system>() : async () {

            for (slice in Vector.vals(mem.slices)) {
                try {
                    let status = await ic.canister_status({
                        canister_id = slice.canister_id;
                    });

                    await ic.update_settings({
                        canister_id = slice.canister_id;
                        settings = {
                            freezing_threshold = ?1296000; // 5 days
                            controllers = ?status.settings.controllers;
                            memory_allocation = null;
                            compute_allocation = null;
                        };
                    });
                } catch (err) {
                    _eventlog.add("ERR : Failed update_slice_settings " # Error.message(err));
                };
            };
        };

        public func canister_info() : CanisterInfo {
            {
                cycles = ExperimentalCycles.balance();
            };
        };

        // Autoupgrade every time this canister gets upgraded
        ignore Timer.setTimer<system>(
            #seconds 1,
            func() : async () {

                _eventlog.add("OK : Updating pair canisters settings started");
                await update_slice_settings<system>();
                _eventlog.add("OK : Updating pair canisters settings ended");

                _eventlog.add("OK : Upgrade of pair canisters started");
                await upgrade_slices<system>();
                _eventlog.add("OK : Upgrade of pair canisters ended");

            },
        );

        ignore Timer.recurringTimer<system>(
            #seconds SLICE_CYCLES_REFILL_SEC,
            func() : async () {
                try {
                    await cycle_maintenance<system>();
                } catch (err) {
                    _eventlog.add("ERR : Failed to refill slices " # Error.message(err));
                };
            },
        );

        public func show_log() : [?Text] {
            _eventlog.get();
        };

        ignore Timer.setTimer<system>(
            #seconds 10,
            func() : async () {
                _eventlog.add("New slices!!");
                try {
                    await spawn_slices<system>();
                } catch (err) {
                    _eventlog.add("ERR : Failed to spawn slices " # Error.message(err));
                };
            },
        );

        ignore Timer.recurringTimer<system>(
            #seconds 21500,
            func() : async () {
                try {
                    await spawn_slices<system>();
                } catch (err) {
                    _eventlog.add("ERR : Failed to spawn slices " # Error.message(err));
                };
            },
        );

    };
};
