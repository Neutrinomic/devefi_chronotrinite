
import { DF } from "../utils";
import { InsertReq } from "../build/slice.idl";
import path from "path";
describe('Basic', () => {

  let d: ReturnType<typeof DF>

  beforeAll(async () => { d = DF(); await d.beforeAll(); });

  afterAll(async () => { await d.afterAll(); });


  it(`Write`, async () => {

    let data : InsertReq = { 
        path: "person/one",
        data: {
          FLOAT: [
            [d.tid(ago(77,0),1), 123],
            [d.tid(ago(44,0),1), 123],
            [d.tid(ago(43,23),2), 333],
            [d.tid(ago(3,4),2), 444],
            [d.tid(ago(4,5),3), 555],
            [d.tid(ago(5,6),4), 345],
          ]
        }
      }

    await d.insert(data);

  });

  it(`Read`, async () => {

    let rez = await d.read({
      from : d.tid(ago(80,0), 0),
      to: d.tid(ago(0,0), 0),
      path: "person/one"
    });

    d.inspect(rez);
  });

});

function ago(days: number, min:number): number {
    return Math.round((Date.now()/1000) - days * 24 * 60 * 60 - min * 60);
} 