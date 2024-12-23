export const idlFactory = ({ IDL }) => {
  const Direction = IDL.Variant({ 'bwd' : IDL.Null, 'fwd' : IDL.Null });
  const C_Path = IDL.Text;
  const ChannelSearchReq = IDL.Record({
    'direction' : Direction,
    'from' : IDL.Nat64,
    'path' : IDL.Variant({ 'exact' : C_Path, 'prefix' : C_Path }),
    'limit' : IDL.Nat,
  });
  const SearchReq = IDL.Vec(ChannelSearchReq);
  const QueryReq = IDL.Variant({ 'search' : SearchReq });
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
  const SearchResp = IDL.Vec(IDL.Tuple(C_Path, ChronoChannelShared));
  const QueryResp = IDL.Variant({ 'search' : SearchResp });
  const InsertReq = IDL.Record({
    'data' : ChronoChannelShared,
    'path' : C_Path,
  });
  const Slice = IDL.Service({
    'chrono_query' : IDL.Func(
        [IDL.Vec(QueryReq)],
        [IDL.Vec(QueryResp)],
        ['query'],
      ),
    'insert' : IDL.Func([IDL.Vec(InsertReq)], [], []),
    'subscribe' : IDL.Func([IDL.Text], [], []),
  });
  return Slice;
};
export const init = ({ IDL }) => {
  return [IDL.Record({ 'router' : IDL.Principal })];
};
