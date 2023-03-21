type rec t<'res, 'db> =
  | Skip
  | Query('res)
  | Column(Schema_Column.t<'res, 'db>)
  | Literal('res)

type unknownNode = t<unknown, unknown>

external toUnknown: t<_> => unknownNode = "%identity"
external toUnknownArray: array<t<_>> => array<unknownNode> = "%identity"
external dictFromRecord: 'a => Js.Dict.t<unknownNode> = "%identity"

let fromAny = any => {
  let any = Obj.magic(any)
  let maybeNodeType: option<NodeType.t> = any->Dict.get("nodeType")

  switch maybeNodeType {
  | Some(#SKIP) => Skip
  | Some(#COLUMN) => Column(any)
  | Some(#QUERY) => Query(any)
  | None => Literal(any)
  }
}
