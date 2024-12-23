import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type C_Path = string;
export interface ChannelSearchReq {
  'direction' : Direction,
  'from' : bigint,
  'path' : { 'exact' : C_Path } |
    { 'prefix' : C_Path },
  'limit' : bigint,
}
export type ChronoChannelShared = { 'AF' : Array<ChronoEvent> } |
  { 'AFN' : Array<ChronoEvent_1> } |
  { 'INT' : Array<ChronoEvent_4> } |
  { 'NAT' : Array<ChronoEvent_5> } |
  { 'TEXT' : Array<ChronoEvent_6> } |
  { 'CANDID' : Array<ChronoEvent_2> } |
  { 'FLOAT' : Array<ChronoEvent_3> };
export type ChronoEvent = [TID, Array<number>];
export type ChronoEvent_1 = [TID, Array<[number, bigint]>];
export type ChronoEvent_2 = [TID, Uint8Array | number[]];
export type ChronoEvent_3 = [TID, number];
export type ChronoEvent_4 = [TID, bigint];
export type ChronoEvent_5 = [TID, bigint];
export type ChronoEvent_6 = [TID, string];
export type Direction = { 'bwd' : null } |
  { 'fwd' : null };
export interface InsertReq { 'data' : ChronoChannelShared, 'path' : C_Path }
export type QueryReq = { 'search' : SearchReq };
export type QueryResp = { 'search' : SearchResp };
export type SearchReq = Array<ChannelSearchReq>;
export type SearchResp = Array<[C_Path, ChronoChannelShared]>;
export interface Slice {
  'chrono_query' : ActorMethod<[Array<QueryReq>], Array<QueryResp>>,
  'insert' : ActorMethod<[Array<InsertReq>], undefined>,
  'subscribe' : ActorMethod<[string], undefined>,
}
export type TID = bigint;
export interface _SERVICE extends Slice {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
