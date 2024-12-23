import MU "mo:mosup";
import BTree "mo:stableheapbtreemap/BTree";
import SWB "mo:swbstable/Stable";
import Vector "mo:vector";
import Map "mo:map/Map";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";

module {

    public module ChronoSlice {

        public type Mem = {
            main : BTree.BTree<Text, ChronoChannelMem>;
            access : Map.Map<Principal, C_Path>;
            slice_from : Nat32;
            slice_to : Nat32;
            router : Principal;
        };

        public func new(init : InitArgs) : MU.MemShell<Mem> = MU.new<Mem>({
            main = BTree.init<C_Path, ChronoChannelMem>(?32);
            access = Map.new<Principal, C_Path>();
            slice_from = init.slice_from;
            slice_to = init.slice_to;
            router = init.router;
        });

        public type TID = Nat64;
        public type C_Path = Text;

        public type ChronoChannelMem = {
            #FLOAT : BTree.BTree<TID, Float>;
            #NAT : BTree.BTree<TID, Nat>;
            #INT : BTree.BTree<TID, Int>;
            #AF : BTree.BTree<TID, [Float]>;
            #AFN : BTree.BTree<TID, [(Float, Nat)]>;
            #TEXT : BTree.BTree<TID, Text>;
            #CANDID : BTree.BTree<TID, Blob>;
        };

        public type InitArgs = {
            slice_from : Nat32;
            slice_to : Nat32;
            router : Principal;
        };
    };

    public module ChronoClient {

        public type WriteSlice = {
            id : Nat;
            slice : MU.MemShell<ChronoSlice.Mem>;
            var frozen : Bool;
            var last_attempt : Nat32;
            var attempts : Nat32;
            var size : Nat;
            created : Nat32;
            slice_canister : Principal;
            slice_from : Nat32;
            slice_to : Nat32;
        };

        public type Mem = {
            subscriptions : Map.Map<Text, Subscription>;
            synced_slice : MU.MemShell<ChronoSlice.Mem>;
            write : Map.Map<Nat, WriteSlice>;
            var router_slices : [(Principal, Nat32, Nat32)];
            var next_local_write_id : Nat;
            router : Principal;
        };

        public type Subscription = {
            var subscribers : Nat;
            var keep_items : Nat;
        };

        public func new({
            router : Principal;
        }) : MU.MemShell<Mem> = MU.new<Mem>({
            subscriptions = Map.new<Text, Subscription>();
            synced_slice = ChronoSlice.new({
                slice_from = 0;
                slice_to = 4294967295; // February 7, 2106 (Fix it later ;)
                router;
            });
            write = Map.new<Nat, WriteSlice>();
            var router_slices = [];
            var next_local_write_id = 0;
            router;
        });

    };

    public module ChronoRouter {

        public type Mem = {
            main : BTree.BTree<Text, Principal>;
            routerlog : SWB.StableData<Text>;
            slices : Vector.Vector<SliceCan>;
            access : Map.Map<Principal, Text>;
        };

        public type SliceCan = {
            slice_from : Nat32;
            slice_to : Nat32;
            canister_id : Principal;
        };

        public func new() : MU.MemShell<Mem> = MU.new<Mem>({
            main = BTree.init<Text, Principal>(?32);
            routerlog = SWB.SlidingWindowBufferNewMem<Text>();
            slices = Vector.new<SliceCan>();
            access = Map.new<Principal, Text>();
        });

    };

};
