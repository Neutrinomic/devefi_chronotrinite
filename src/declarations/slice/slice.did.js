export const idlFactory = ({ IDL }) => {
  const InitArgs = IDL.Record({
    'slice_from' : IDL.Nat32,
    'slice_to' : IDL.Nat32,
    'router' : IDL.Principal,
  });
  const CanisterInfo = IDL.Record({ 'cycles' : IDL.Nat });
  const Direction = IDL.Variant({ 'bwd' : IDL.Null, 'fwd' : IDL.Null });
  const C_Path = IDL.Text;
  const ChannelSearchReq = IDL.Record({
    'direction' : Direction,
    'from' : IDL.Nat64,
    'path' : IDL.Variant({ 'exact' : C_Path, 'prefix' : C_Path }),
    'limit' : IDL.Nat,
  });
  const SearchReq = IDL.Vec(ChannelSearchReq);
  const TID = IDL.Nat64;
  const ChronoEvent = IDL.Tuple(TID, IDL.Vec(IDL.Float64));
  const ChronoEvent_1 = IDL.Tuple(
    TID,
    IDL.Vec(IDL.Tuple(IDL.Float64, IDL.Nat)),
  );
  const ChronoEvent_4 = IDL.Tuple(TID, IDL.Int);
  const ChronoEvent_5 = IDL.Tuple(TID, IDL.Nat);
  const ChronoEvent_6 = IDL.Tuple(TID, IDL.Text);
  const ChronoEvent_2 = IDL.Tuple(TID, IDL.Vec(IDL.Nat8));
  const ChronoEvent_3 = IDL.Tuple(TID, IDL.Float64);
  const ChronoChannelShared = IDL.Variant({
    'AF' : IDL.Vec(ChronoEvent),
    'AFN' : IDL.Vec(ChronoEvent_1),
    'INT' : IDL.Vec(ChronoEvent_4),
    'NAT' : IDL.Vec(ChronoEvent_5),
    'TEXT' : IDL.Vec(ChronoEvent_6),
    'CANDID' : IDL.Vec(ChronoEvent_2),
    'FLOAT' : IDL.Vec(ChronoEvent_3),
  });
  const InsertReq = IDL.Record({
    'data' : ChronoChannelShared,
    'path' : C_Path,
  });
  const ChronoCommandReq = IDL.Variant({
    'search' : SearchReq,
    'insert' : IDL.Vec(InsertReq),
  });
  const SearchResp = IDL.Vec(IDL.Tuple(C_Path, ChronoChannelShared));
  const ChronoCommandResp = IDL.Variant({
    'search' : SearchResp,
    'insert' : IDL.Null,
  });
  const QueryReq = IDL.Variant({ 'search' : SearchReq });
  const QueryResp = IDL.Variant({ 'search' : SearchResp });
  const ChronoSetAccess = IDL.Vec(IDL.Tuple(IDL.Principal, C_Path));
  const Slice = IDL.Service({
    'canister_info' : IDL.Func([], [CanisterInfo], ['query']),
    'chrono_command' : IDL.Func(
        [IDL.Vec(ChronoCommandReq)],
        [IDL.Vec(ChronoCommandResp)],
        [],
      ),
    'chrono_query' : IDL.Func(
        [IDL.Vec(QueryReq)],
        [IDL.Vec(QueryResp)],
        ['query'],
      ),
    'chrono_set_access' : IDL.Func([ChronoSetAccess], [], []),
    'deposit_cycles' : IDL.Func([], [], []),
  });
  return Slice;
};
export const init = ({ IDL }) => {
  const InitArgs = IDL.Record({
    'slice_from' : IDL.Nat32,
    'slice_to' : IDL.Nat32,
    'router' : IDL.Principal,
  });
  return [InitArgs];
};
