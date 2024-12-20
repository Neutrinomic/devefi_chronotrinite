import SWB "mo:swbstable/Stable";
import U "./utils";
import Array "mo:base/Array";
import Nat64 "mo:base/Nat64";

module {

    public class ErrLog({
        mem : SWB.SlidingWindowBuffer<Text>
    }) { 

        public func add(e: Text) {
     
            ignore mem.add(Nat64.toText(U.now()/1_000_000_000) # " : " # e);
            if (mem.len() > 1000) { // Max 1000
                mem.delete(1); // Delete 1 element from the beginning
            };

        };

        public func get() : [?Text] {
          let start = mem.start();

          Array.tabulate(
                mem.len(),
                func(i : Nat) : ?Text {
                    mem.getOpt(start + i);
                },
            );
        };

    }
}