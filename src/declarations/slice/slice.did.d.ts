import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type C_Path = string;
export interface CanisterInfo { 'cycles' : bigint }
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
export type ChronoCommandReq = { 'search' : SearchReq } |
  { 'insert' : Array<InsertReq> };
export type ChronoCommandResp = { 'search' : SearchResp } |
  { 'insert' : null };
export type ChronoEvent = [TID, Array<number>];
export type ChronoEvent_1 = [TID, Array<[number, bigint]>];
export type ChronoEvent_2 = [TID, Uint8Array | number[]];
export type ChronoEvent_3 = [TID, number];
export type ChronoEvent_4 = [TID, bigint];
export type ChronoEvent_5 = [TID, bigint];
export type ChronoEvent_6 = [TID, string];
export type ChronoSetAccess = Array<[Principal, C_Path]>;
export type Direction = { 'bwd' : null } |
  { 'fwd' : null };
export interface InitArgs {
  'slice_from' : number,
  'slice_to' : number,
  'router' : Principal,
}
export interface InsertReq { 'data' : ChronoChannelShared, 'path' : C_Path }
export type QueryReq = { 'search' : SearchReq };
export type QueryResp = { 'search' : SearchResp };
export type SearchReq = Array<ChannelSearchReq>;
export type SearchResp = Array<[C_Path, ChronoChannelShared]>;
export interface Slice {
  'canister_info' : ActorMethod<[], CanisterInfo>,
  'chrono_command' : ActorMethod<
    [Array<ChronoCommandReq>],
    Array<ChronoCommandResp>
  >,
  'chrono_query' : ActorMethod<[Array<QueryReq>], Array<QueryResp>>,
  'chrono_set_access' : ActorMethod<[ChronoSetAccess], undefined>,
  'deposit_cycles' : ActorMethod<[], undefined>,
}
export type TID = bigint;
export interface _SERVICE extends Slice {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
