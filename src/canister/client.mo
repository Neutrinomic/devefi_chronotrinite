import C "../../src/client";
import S "../../src/slice";

shared ({caller}) actor class  Slice({router: Principal})  {


    stable let chrono_mem_1 = C.Mem.ChronoClient.V1.new({router});
    let chrono = C.ChronoClient<system>({ xmem = chrono_mem_1 });
    
    public shared func insert(input: [C.InsertReq]) : async () {
        chrono.insert(input);
    };

    public shared func subscribe(path: Text) : async () {
        chrono.subscribe(path, 400);
    };

    public query func chrono_query(req: [S.QueryReq]) : async [S.QueryResp] {
        chrono.chrono_query(req);
    };

}
