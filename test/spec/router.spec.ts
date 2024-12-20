
import { DF } from "../utils";
import path from "path";
import fs from "fs";

describe('Basic', () => {

  let d: ReturnType<typeof DF>

  beforeAll(async () => { d = DF(); await d.beforeAll(); });

  afterAll(async () => { await d.afterAll(); });


  it(`Check create`, async () => {


    let slices = await d.chrono.get_slices();
    // fs.writeFileSync(path.join(__dirname, 'slices.json'), JSON.stringify(d.toState(slices), null, 2));
    // d.inspect(slices);
    expect(slices.length).toBeGreaterThan(27);
    
    let log = await d.chrono.show_log();
    // fs.writeFileSync(path.join(__dirname, 'log.json'), JSON.stringify(d.toState(log), null, 2));
    // d.inspect(log);
    expect(log.length).toBeGreaterThan(10);

    let info = await d.chrono.canister_info();

    // d.inspect(info);
    
  });


      

});

