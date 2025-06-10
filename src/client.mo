import MU "mo:mosup";
import Ver1 "./memory/v1";
import Slice "./slice";
import Map "mo:map/Map";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Vector "mo:vector";
import Option "mo:base/Option";
import Array "mo:base/Array";
import U "./utils";
import Timer "mo:base/Timer";
import Error "mo:base/Error";
module {

    public module Mem {
        public module ChronoClient {
            public let V1 = Ver1.ChronoClient;
        };
        public module ChronoSlice {
            public let V1 = Ver1.ChronoSlice;
        };
    };

    public let VM = Mem.ChronoClient.V1;
    public let VMSlice = Mem.ChronoSlice.V1;

    public type InsertReq = Slice.InsertReq;
    public type InsertOne = Slice.InsertOne;

    public class ChronoClient<system>({ xmem : MU.MemShell<VM.Mem> }) {
        let mem = MU.access(xmem);
        mem.synced_slice.inner := null;
        // let synced_slice = Slice.ChronoSlice({ xmem = mem.synced_slice });

        // public func search(req : Slice.SearchReq) : Slice.SearchResp {
        //     synced_slice.search(req);
        // };

        type LastWrite = {
            slice : Slice.ChronoSlice;
            write : VM.WriteSlice;
        };

        var last_write : ?LastWrite = null;

        // public func chrono_query(req : [Slice.QueryReq]) : [Slice.QueryResp] {
        //     synced_slice.chrono_query(req);
        // };

        public func insert(input : [Slice.InsertReq]) : () {

            for (req in input.vals()) {
                switch (req.data) {
                    case (#FLOAT(arr)) {
                        for (x in arr.vals()) {
                            insert_one((req.path, x.0, #FLOAT(x.1)));
                        };
                    };
                    case (#NAT(arr)) {
                        for (x in arr.vals()) {
                            insert_one((req.path, x.0, #NAT(x.1)));
                        };
                    };
                    case (#INT(arr)) {
                        for (x in arr.vals()) {
                            insert_one((req.path, x.0, #INT(x.1)));
                        };
                    };
                    case (#AF(arr)) {
                        for (x in arr.vals()) {
                            insert_one((req.path, x.0, #AF(x.1)));
                        };
                    };
                    case (#AFN(arr)) {
                        for (x in arr.vals()) {
                            insert_one((req.path, x.0, #AFN(x.1)));
                        };
                    };
                    case (#TEXT(arr)) {
                        for (x in arr.vals()) {
                            insert_one((req.path, x.0, #TEXT(x.1)));
                        };
                    };
                    case (#CANDID(arr)) {
                        for (x in arr.vals()) {
                            insert_one((req.path, x.0, #CANDID(x.1)));
                        };
                    };
                };
            };
        };

        public func insert_one(input : InsertOne) : () {
            if (mem.router_slices.size() == 0) Debug.trap("No router slices available");
            // synced_slice.insert_one(input);

            let input_size_bytes = Slice.get_input_size_bytes(input);

            // Last write matches and is available
            ignore do ? {
                let slice = last_write!.slice;
                let write = last_write!.write;
                if (
                    input.1 >= slice._slice_from_tid and input.1 < slice._slice_to_tid and write.frozen == false and write.size + input_size_bytes < 512000
                ) {
                    return slice.insert_one(input);
                };
            };

            let ts = Slice.tid_to_ts(input.1);

            // Search in existing write slices
            label existing_search for (write in Map.vals(mem.write)) {
                if (write.frozen or write.size + input_size_bytes > 512000) continue existing_search;
                if (ts >= write.slice_from and ts < write.slice_to) {
                    let slice = Slice.ChronoSlice({ xmem = write.slice });
                    last_write := ?{
                        slice;
                        write;
                    };
                    return slice.insert_one(input);
                };
            };

            // Have to create a new write slice and cache it
            let ?target_slice = Array.find<(Principal, Nat32, Nat32)>(
                mem.router_slices,
                func(slice) : Bool = (ts >= slice.1 and ts < slice.2),
            ) else Debug.trap("No avail router slice found!");

            let id = mem.next_local_write_id;
            mem.next_local_write_id += 1;

            let new_write : VM.WriteSlice = {
                id;
                slice = VMSlice.new({
                    slice_from = target_slice.1;
                    slice_to = target_slice.2;
                    router = mem.router;
                });
                created = U.now_sec();
                slice_from = target_slice.1;
                slice_to = target_slice.2;
                slice_canister = target_slice.0;
                var frozen = false;
                var last_attempt = 0;
                var attempts = 0;
                var size = input_size_bytes;
            };

            let slice = Slice.ChronoSlice({ xmem = new_write.slice });

            last_write := ?{
                slice;
                write = new_write;
            };

            Map.set(mem.write, Map.nhash, id, new_write);

            return slice.insert_one(input);

        };

        type SliceCan = actor {
            chrono_command : shared ([Slice.ChronoCommandReq]) -> async [Slice.ChronoCommandResp];
        };

        let READ_FROM_MASTER_WITHOUT_WRITE = false;

        public func sync() : async () {

            // Repeatedly send write slices to the last known slice
            // Debug.print("1) Syncing");
            for (write in Map.vals(mem.write)) {
                write.frozen := true;
            };

            // // Debug.print("2) Syncing");
            // if (READ_FROM_MASTER_WITHOUT_WRITE) {
            //     try {
            //     if (Map.size(mem.write) == 0) {
            //         let last_slice = mem.router_slices[mem.router_slices.size() - 1];
            //         let can = actor (Principal.toText(last_slice.0)) : SliceCan;

            //         let resp = await can.chrono_command([
            //             #search(get_search_req()),
            //         ]);
                    
            //         for (resp_cmd in resp.vals()) {
            //             switch(resp_cmd) {
            //                 case (#search(chans)) {
            //                     for ((path, chan) in chans.vals()) {
            //                         for (item in Slice.data_single_to_val(chan).vals()) {
            //                             synced_slice.insert_one(path, item.0, item.1);
            //                         }
            //                     }   
            //                 };
            //                 case (_) ();
            //             }
            //         };
            //     };
            //     } catch (e) {
            //         Debug.print("Error read syncing : " # debug_show(Error.message(e)));
            //     };
            // };

            try {
                label write_loop for (write in Map.vals(mem.write)) {
                    // Debug.print("3) Writing attempt" # debug_show({
                    //     attempts = write.attempts;
                    //     last_attempt = write.last_attempt;
                    //     diff = U.now_sec() - write.last_attempt;
                    //     size = write.size / 1024 / 1024; // in MB
                    // }));
                    // if (write.attempts > 5) continue write_loop;
                    // if (write.last_attempt + 120 < U.now_sec()) continue write_loop;

                    write.attempts += 1;
                    write.last_attempt := U.now_sec();

                    let can = actor (Principal.toText(write.slice_canister)) : SliceCan;
                    let write_slice = Slice.ChronoSlice({ xmem = write.slice });

                    let req = write_slice.mem_to_input();
                    // Debug.print("4) Writing");
                    ignore await can.chrono_command([
                        #insert(req),
                        // #search(get_search_req()),
                    ]);

                    // for (resp_cmd in resp.vals()) {
                    //     switch(resp_cmd) {
                    //         case (#search(chans)) {
                    //             for ((path, chan) in chans.vals()) {
                    //                 for (item in Slice.data_single_to_val(chan).vals()) {
                    //                     synced_slice.insert_one(path, item.0, item.1);
                    //                 }
                    //             }
                    //         };
                    //         case (_) ();
                    //     }
                    // };

                    ignore Map.remove(mem.write, Map.nhash, write.id);
                    break write_loop;
                };
            } catch (e) {
                Debug.print("Error write syncing: " # debug_show(Error.message(e)));
            };

        };

        private func get_search_req() : Slice.SearchReq {
            let now = U.now_sec();
            let req = Vector.new<Slice.ChannelSearchReq>();
            for ((path,sub) in Map.entries(mem.subscriptions)) {
                Vector.add<Slice.ChannelSearchReq>(req, {
                    path = #exact(path);
                    direction = #fwd;
                    from = Slice.ts_to_tid(now - 10); // TODO: get last slice id and reduce 5sec
                    limit = 100;
                });
            };
            Vector.toArray(req);
        };

        ignore Timer.recurringTimer<system>(#seconds 20, sync);

        type RouterCan = actor {
            get_slices : shared () -> async [(Principal, Nat32, Nat32)];
        };

        public func refresh_router_slices() : async () {
            // Get the latest slices from the router every 2 hours (New one should be created 6 hours before its time comes)

            let can = actor (Principal.toText(mem.router)) : RouterCan;
            let slices = await can.get_slices();
            mem.router_slices := slices;
        };

        ignore Timer.setTimer<system>(#seconds 1, refresh_router_slices);
        ignore Timer.recurringTimer<system>(#seconds 7200, refresh_router_slices);

        public func subscribe(path : Text, keep_items : Nat) : () {
            switch (Map.get(mem.subscriptions, Map.thash, path)) {
                case (?sub) {
                    sub.subscribers += 1;
                    sub.keep_items := Nat.max(sub.keep_items, keep_items);
                };
                case (null) {
                    Map.set(
                        mem.subscriptions,
                        Map.thash,
                        path,
                        {
                            var subscribers = 1;
                            var keep_items = keep_items;
                        },
                    );
                };
            };
        };

        public func unsubscribe(path : Text) : async () {
            switch (Map.get(mem.subscriptions, Map.thash, path)) {
                case (?sub) {
                    sub.subscribers -= 1;
                    if (sub.subscribers == 0) {
                        ignore Map.remove(mem.subscriptions, Map.thash, path);
                    };
                };
                case (null) ();
            };
        };
    };
};



