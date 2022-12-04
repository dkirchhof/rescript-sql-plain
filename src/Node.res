type rec t<'res, 'db> =
  | Skip
  | Query('res)
  | Column(Schema_Column.t<'res, 'db>)
  | Literal('res)

type unknownNode = t<unknown, unknown>

external toUnknown: t<_> => unknownNode = "%identity"
external toUnknownArray: array<t<_>> => array<unknownNode> = "%identity"
external dictFromRecord: 'a => Js.Dict.t<unknownNode> = "%identity"
