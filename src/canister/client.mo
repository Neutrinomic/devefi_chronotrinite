import C "../../src/client";

shared ({caller}) actor class  Slice({router: Principal})  {


    stable let chrono_mem_1 = C.Mem.ChronoClient.V1.new({router});
    let chrono = C.ChronoClient<system>({ xmem = chrono_mem_1 });
    
    public shared func insert(input: [C.InsertReq]) : async () {
        chrono.insert(input);
    };

}
