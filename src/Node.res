type t<'res, 'db> = Skip | Column(Schema_Column.t<'res, 'db>) | Literal('res)

type unknownNode = t<unknown, unknown>
type intNode = t<int, int>
type stringNode = t<string, string>
type dateNode = t<Js.Date.t, string>

external toUnknown: t<_> => unknownNode = "%identity"
external dictFromRecord: 'a => Js.Dict.t<unknownNode> = "%identity"
external recordFromDict: Js.Dict.t<unknownNode> => 'a = "%identity"

let getColumnExn = node => {
  switch node {
  | Column(column) => column
  | _ => Js.Exn.raiseError("This node should be a column.")
  }
}

module Record = {
  let mapEntries = (record: 'a, f): 'a => {
    record->dictFromRecord->Js.Dict.entries->Js.Array2.map(f)->Js.Dict.fromArray->recordFromDict
  }
}
