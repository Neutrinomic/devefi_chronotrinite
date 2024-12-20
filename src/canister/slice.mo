import C "../../src/slice";
import ExperimentalCycles "mo:base/ExperimentalCycles";

shared ({caller}) actor class  Slice(init : C.Mem.ChronoSlice.V1.InitArgs)  {


    stable let chrono_mem_1 = C.Mem.ChronoSlice.V1.new(init);
    let chrono = C.ChronoSlice({ xmem = chrono_mem_1 });
    
    public shared({caller}) func chrono_command(cmd: [C.ChronoCommandReq]) : async [C.ChronoCommandResp] {
        chrono.chrono_command(?caller, cmd);
    };

    public query func chrono_query(req: [C.QueryReq]) : async [C.QueryResp] {
        chrono.chrono_query(req);
    };

    public shared({caller}) func chrono_set_access(req: C.ChronoSetAccess) : async () {
        chrono.chrono_set_access(caller, req);
    };

    public shared func deposit_cycles() : async () {
        let amount = ExperimentalCycles.available();
        let accepted = ExperimentalCycles.accept<system>(amount);
        assert (accepted == amount);
    };

    public query func canister_info() : async C.CanisterInfo {
        chrono.canister_info();
    };

}
