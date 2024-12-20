import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";

module {
     public func now() : Nat64 {
        Nat64.fromNat(Int.abs(Time.now()));
    };

    public func now_sec() : Nat32 {
        Nat32.fromNat(Nat64.toNat(now()) / 1_000_000_000);
    }
}