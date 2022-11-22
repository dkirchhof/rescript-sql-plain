type t<'res, 'db> = Skip | Column(Schema_Column.t<'res, 'db>) | Literal('res)

type unknownNode = t<unknown, unknown>
type intNode = t<int, int>
type stringNode = t<string, string>
type dateNode = t<Js.Date.t, string>

external dictFromRecord: 'a => Js.Dict.t<t<unknown, unknown>> = "%identity"
