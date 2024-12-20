
import { DF } from "../utils";
import { InsertReq } from "../build/slice.idl";
import path from "path";
describe('Client basic', () => {

  let d: ReturnType<typeof DF>

  beforeAll(async () => { d = DF(); await d.beforeAll(); });

  afterAll(async () => { await d.afterAll(); });


  it(`Client`, async () => {

    let data : InsertReq = { 
        path: "person/one",
        data: {
          FLOAT: [
            [d.tid(ago(77,0),1), 1],
            [d.tid(ago(44,0),1), 2],
            [d.tid(ago(43,23),2), 3],
            [d.tid(ago(3,4),2), 4],
            [d.tid(ago(4,5),3), 5],
            [d.tid(ago(5,6),4), 6],
          ]
        }
      }

    await d.client.insert([data]);

    await d.passTime(100);
  });

  it(`Read`, async () => {

    let rez = await d.read({
      from : d.tid(ago(80,0), 0),
      to: d.tid(ago(0,0), 0),
      path: "person/one"
    });

    d.inspect(rez);
  });

  it(`Write more`, async () => {

    let data : InsertReq = { 
        path: "person/two",
        data: {
          FLOAT: [
            [d.tid(ago(77,0),1), 1],
            [d.tid(ago(4,5),3), 3],
            [d.tid(ago(5,6),4), 4],
          ]
        }
      }
  
    await d.client.insert([data]);
  
    await d.passTime(100);
  });

  it(`Read again`, async () => {

    let rez = await d.read({
      from : d.tid(ago(80,0), 0),
      to: d.tid(ago(0,0), 0),
      path: "person/two"
    });

    d.inspect(rez);
  });

  it(`Write more person one`, async () => {

    let data : InsertReq = { 
        path: "person/one",
        data: {
          FLOAT: [
            [d.tid(ago(78,1),10), 10],
            [d.tid(ago(33,1),11), 11],
            [d.tid(ago(5,1),12), 12],
            [d.tid(ago(3,3),13), 13],
          ]
        }
      }
  
    await d.client.insert([data]);
  
    await d.passTime(100);
  });

  it(`Read again person one`, async () => {

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