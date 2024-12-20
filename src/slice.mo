import Result "mo:base/Result";
import BTree "mo:stableheapbtreemap/BTree";
import Text "mo:base/Text";
import U "./utils";
import Vector "mo:vector";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import Ver1 "./memory/v1";
import MU "mo:mosup";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Map "mo:map/Map";
import Array "mo:base/Array";

module {

    public module Mem {
        public module ChronoSlice {
            public let V1 = Ver1.ChronoSlice;
        };
    };

    public let VM = Mem.ChronoSlice.V1;

    public type TID = VM.TID;
    public type C_Path = VM.C_Path;
    public type C_Candid_Id = VM.C_Candid_Id;
    public type ChronoChannelMem = VM.ChronoChannelMem;

    type R<A, B> = Result.Result<A, B>;

    public type CanisterInfo = {
        cycles : Nat;
    };

    public type ChronoEvent<T> = (TID, T);

    public type ChronoChannelShared = {
        #FLOAT : [ChronoEvent<Float>];
        #NAT : [ChronoEvent<Nat>];
        #INT : [ChronoEvent<Int>];
        #AF : [ChronoEvent<[Float]>];
        #AFN : [ChronoEvent<[(Float, Nat)]>];
        #TEXT : [ChronoEvent<Text>];
        #CANDID : [ChronoEvent<(C_Candid_Id, Blob)>];
    };

    public type Value = {
        #FLOAT : Float;
        #NAT : Nat;
        #INT : Int;
        #AF : [Float];
        #AFN : [(Float, Nat)];
        #TEXT : Text;
        #CANDID : (C_Candid_Id, Blob);
    };

    public type InsertReq = {
        path : C_Path;
        data : ChronoChannelShared;
    };
    public type InsertOne = (C_Path, TID, Value);

    public type SearchReq = [ChannelSearchReq];
    public type SearchResp = [(C_Path, ChronoChannelShared)];

    public type ChannelSearchReq = {
        path : {
            #exact : C_Path;
            #prefix : C_Path;
        };
        direction : BTree.Direction;
        limit : Nat;
        from : Nat64;
    };

    public type ChronoCommandReq = {
        #insert : [InsertReq];
        #search : SearchReq;
    };

    public type ChronoCommandResp = {
        #insert : ();
        #search : SearchResp;
    };

    public type QueryReq = {
        #search : SearchReq;
    };

    public type QueryResp = {
        #search : SearchResp;
    };

    public type ChronoSetAccess = [(Principal, C_Path)];

    public func get_input_size_bytes(input : InsertOne) : Nat {
        let (_, _, value) = input;
        switch (value) {
            case (#FLOAT(_)) 8;
            case (#NAT(_)) 8;
            case (#INT(_)) 8;
            case (#AF(arr)) arr.size() * 8;
            case (#AFN(arr)) arr.size() * 16;
            case (#TEXT(txt)) txt.size() * 2;
            case (#CANDID(_, blob)) blob.size();
        };
    };

    public func tid_to_ts(tid : Nat64) : Nat32 {
        Nat32.fromNat(Nat64.toNat(tid >> 32));
    };

    public func ts_to_tid(ts : Nat32) : Nat64 {
        Nat64.fromNat(Nat32.toNat(ts)) << 32;
    };

    public class ChronoSlice({ xmem : MU.MemShell<VM.Mem> }) {
        let mem = MU.access(xmem);

        public let _slice_from_tid : Nat64 = ts_to_tid(mem.slice_from);
        public let _slice_to_tid : Nat64 = ts_to_tid(mem.slice_to);

        public func chrono_command(caller : ?Principal, commands : [ChronoCommandReq]) : [ChronoCommandResp] {
            let rez = Vector.new<ChronoCommandResp>();
            for (cmd in commands.vals()) {
                Vector.add(
                    rez,
                    switch (cmd) {
                        case (#insert(i)) #insert(insert(caller, i));
                        case (#search(s)) #search(search(s));
                    },
                );
            };
            Vector.toArray(rez);
        };

        public func chrono_set_access(caller : Principal, req : ChronoSetAccess) : () {
            if (caller != mem.router) Debug.trap("Access denied");
            Map.clear(mem.access);
            for (acc in req.vals()) {
                Map.set(mem.access, Map.phash, acc.0, acc.1);
            };
        };

        private func has_access(caller : Principal, path : C_Path) : Bool {
            switch (Map.get(mem.access, Map.phash, caller)) {
                case (?p) Text.startsWith(path, #text(p));
                case (null) false;
            };
        };

        public func chrono_query(req : [QueryReq]) : [QueryResp] {
            let rez = Vector.new<QueryResp>();
            for (cmd in req.vals()) {
                Vector.add(
                    rez,
                    switch (cmd) {
                        case (#search(s)) #search(search(s));
                    },
                );
            };
            Vector.toArray(rez);
        };

        public func insert(caller : ?Principal, input : [InsertReq]) : () {
            for (req in input.vals()) {
                ignore do ? { if (not has_access(caller!, req.path)) Debug.trap("Access denied"); };

                switch(req.data) {
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

        public func search(search : SearchReq) : SearchResp {

            let rez_channels = Vector.new<(C_Path, ChronoChannelShared)>();

            label searchloop for (chan in search.vals()) {
                switch (chan.path) {
                    case (#exact(p)) {
                        let ?x = BTree.get(mem.main, Text.compare, p) else continue searchloop;
                        Vector.add(rez_channels, (p, get_channel_results(x, chan.direction, chan.from, chan.limit)));
                    };
                    case (#prefix(p)) {
                        let g = BTree.scanLimit(mem.main, Text.compare, p, "~", #fwd, 200);
                        for (x in g.results.vals()) {
                            Vector.add(rez_channels, (x.0, get_channel_results(x.1, chan.direction, chan.from, chan.limit)));
                        };
                    };
                };
            };

            Vector.toArray(rez_channels);

        };

        public func canister_info() : CanisterInfo {
            {
                cycles = ExperimentalCycles.balance();

            };
        };

        private func get_channel_results<A>(chan : ChronoChannelMem, direction : BTree.Direction, from : Nat64, limit : Nat) : ChronoChannelShared {

            switch (chan) {
                case (#FLOAT(btree)) #FLOAT(get_channel_results_inner<Float>(btree, direction, from, limit));
                case (#NAT(btree)) #NAT(get_channel_results_inner<Nat>(btree, direction, from, limit));
                case (#INT(btree)) #INT(get_channel_results_inner<Int>(btree, direction, from, limit));
                case (#AF(btree)) #AF(get_channel_results_inner<[Float]>(btree, direction, from, limit));
                case (#AFN(btree)) #AFN(get_channel_results_inner<[(Float, Nat)]>(btree, direction, from, limit));
                case (#TEXT(btree)) #TEXT(get_channel_results_inner<Text>(btree, direction, from, limit));
                case (#CANDID(btree)) #CANDID(get_channel_results_inner<(C_Candid_Id, Blob)>(btree, direction, from, limit));
            };

        };

        private func get_channel_results_inner<A>(btree : BTree.BTree<TID, A>, direction : BTree.Direction, from : Nat64, limit : Nat) : [ChronoEvent<A>] {
            let rez = Vector.new<ChronoEvent<A>>();

            let search = switch (direction) {
                case (#fwd) BTree.scanLimit<TID, A>(btree, Nat64.compare, from, ^0, direction, limit);
                case (#bwd) BTree.scanLimit<TID, A>(btree, Nat64.compare, 0, from, direction, limit);
            };
            for (x in search.results.vals()) {
                Vector.add(rez, x);
            };
            Vector.toArray(rez);
        };

        private func new_channel( x : Value ) : ChronoChannelMem {
            switch(x) {
                case (#FLOAT(_)) #FLOAT(BTree.init<TID, Float>(?32));
                case (#NAT(_)) #NAT(BTree.init<TID, Nat>(?32));
                case (#INT(_)) #INT(BTree.init<TID, Int>(?32));
                case (#AF(_)) #AF(BTree.init<TID, [Float]>(?32));
                case (#AFN(_)) #AFN(BTree.init<TID, [(Float, Nat)]>(?32));
                case (#TEXT(_)) #TEXT(BTree.init<TID, Text>(?32));
                case (#CANDID(_)) #CANDID(BTree.init<TID, (C_Candid_Id, Blob)>(?32));
            }
        };

        public func insert_one(input : InsertOne) : () {
            
            let (path, tid, value) = input;
            if (tid < _slice_from_tid or tid >= _slice_to_tid) Debug.trap("TID out of slice range");
            let chan = get_create_channel(path, func () = new_channel(value));

            add_to_channel(chan, tid, value);
             
        };

        var last_channel : ?(C_Path, ChronoChannelMem) = null;
        private func get_create_channel(path : Text, create_new : () -> ChronoChannelMem) : ChronoChannelMem {
            ignore do ? { if (last_channel!.0 == path) return last_channel!.1 };

            let chan = switch (BTree.get(mem.main, Text.compare, path)) {
                case (?found) found;
                case (null) {
                    let new_chan : ChronoChannelMem = create_new();
                    ignore BTree.insert(mem.main, Text.compare, path, new_chan);
                    new_chan;
                };
            };
            last_channel := ?(path, chan);
            chan;
        };

        public func add_to_channel(channel : ChronoChannelMem, tid : TID, value : Value) : () {
            switch (value, channel) {
                case (#FLOAT(val), #FLOAT(btree)) ignore BTree.insert(btree, Nat64.compare, tid, val);
                case (#NAT(val), #NAT(btree)) ignore BTree.insert(btree, Nat64.compare, tid, val);
                case (#INT(val), #INT(btree)) ignore BTree.insert(btree, Nat64.compare, tid, val);
                case (#AF(val), #AF(btree)) ignore BTree.insert(btree, Nat64.compare, tid, val);
                case (#AFN(val), #AFN(btree)) ignore BTree.insert(btree, Nat64.compare, tid, val);
                case (#TEXT(val), #TEXT(btree)) ignore BTree.insert(btree, Nat64.compare, tid, val);
                case (#CANDID(val), #CANDID(btree)) ignore BTree.insert(btree, Nat64.compare, tid, val);
                case (_, _) Debug.trap("Invalid value type");
            };
        };

        public func mem_to_input() : [InsertReq] {
            let inputList = Vector.new<InsertReq>();

            for ((path, channelMem) in BTree.entries(mem.main)) {

                let channelReq = switch (channelMem) {
                    case (#FLOAT(events)) {
                        let eventsArray = Vector.new<ChronoEvent<Float>>();
                        for ((tid, payload) in BTree.entries<TID, Float>(events)) {
                            Vector.add(eventsArray, (tid, payload));
                        };
                        {
                            path = path;
                            data = #FLOAT(Vector.toArray(eventsArray));
                        };
                    };
                    case (#NAT(events)) {
                        let eventsArray = Vector.new<ChronoEvent<Nat>>();
                        for ((tid, payload) in BTree.entries<TID, Nat>(events)) {
                            Vector.add(eventsArray, (tid, payload));
                        };
                        {
                            path = path;
                            data = #NAT(Vector.toArray(eventsArray));
                        };
                    };
                    case (#INT(events)) {
                        let eventsArray = Vector.new<ChronoEvent<Int>>();
                        for ((tid, payload) in BTree.entries<TID, Int>(events)) {
                            Vector.add(eventsArray, (tid, payload));
                        };
                        {
                            path = path;
                            data = #INT(Vector.toArray(eventsArray));
                        };
                    };
                    case (#AF(events)) {
                        let eventsArray = Vector.new<ChronoEvent<[Float]>>();
                        for ((tid, payload) in BTree.entries<TID, [Float]>(events)) {
                            Vector.add(eventsArray, (tid, payload));
                        };
                        { path = path; data = #AF(Vector.toArray(eventsArray)) };
                    };
                    case (#AFN(events)) {
                        let eventsArray = Vector.new<ChronoEvent<[(Float, Nat)]>>();
                        for ((tid, payload) in BTree.entries<TID, [(Float, Nat)]>(events)) {
                            Vector.add(eventsArray, (tid, payload));
                        };
                        {
                            path = path;
                            data = #AFN(Vector.toArray(eventsArray));
                        };
                    };
                    case (#TEXT(events)) {
                        let eventsArray = Vector.new<ChronoEvent<Text>>();
                        for ((tid, payload) in BTree.entries<TID, Text>(events)) {
                            Vector.add(eventsArray, (tid, payload));
                        };
                        {
                            path = path;
                            data = #TEXT(Vector.toArray(eventsArray));
                        };
                    };
                    case (#CANDID(events)) {
                        let eventsArray = Vector.new<ChronoEvent<(C_Candid_Id, Blob)>>();
                        for ((tid, payload) in BTree.entries<TID, (C_Candid_Id, Blob)>(events)) {
                            Vector.add(eventsArray, (tid, payload));
                        };
                        {
                            path = path;
                            data = #CANDID(Vector.toArray(eventsArray));
                        };
                    };
                };

                Vector.add(inputList, channelReq);
            };

            Vector.toArray(inputList);
        };
    };
};
