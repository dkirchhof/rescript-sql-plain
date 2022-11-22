type t<'res, 'db> = Skip | Column(Schema_Column.t<'res, 'db>) | Literal('res)

/* type unknown */
/* type unknownCOL = t<unknown, unknown> */

type intCOL = t<int, int>
type stringCOL = t<string, string>
type dateCOL = t<Js.Date.t, string>

external dictFromRecord: 'a => Js.Dict.t<t<unknown, unknown>> = "%identity"
