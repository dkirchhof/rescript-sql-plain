type nodeType = [#SKIP | #QUERY | #COLUMN]

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
  switch Type.Classify.classify(any) {
  | Object(_) => Literal(any)
  | Bool(_) => Literal(any)
  | String(_) => Literal(any)
  }

  /* if Js.Types.test(any, Js.Types.Object) && Belt.Option.isSome(any["nodeType"]) { */
  /*   switch any["nodeType"] { */
  /*   | #SKIP => Skip */
  /*   | #QUERY => any->Obj.magic->Query */
  /*   | #COLUMN => any->Obj.magic->Column */
  /*   } */
  /* } else { */
  /*   any->Obj.magic->Literal */
  /* } */
}
