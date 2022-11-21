type converter<'res, 'db> = {
  dbToRes: 'db => 'res,
  resToDB: 'res => 'db,
}

type t<'res, 'db> = {
  table: string,
  name: string,
  dbType: [#VARCHAR | #INTEGER | #TEXT],
  size: option<int>,
  converter: option<converter<'res, 'db>>,
}

type intColumn = t<int, int>
type stringColumn = t<string, string>
type dateColumn = t<Js.Date.t, string>

type options = {size?: int}

let varchar = (options): stringColumn => {
  table: "",
  name: "",
  dbType: #VARCHAR,
  size: options.size,
  converter: None,
}

let text = (options): stringColumn => {
  table: "",
  name: "",
  dbType: #TEXT,
  size: options.size,
  converter: None,
}

let integer = (options): intColumn => {
  table: "",
  name: "",
  dbType: #INTEGER,
  size: options.size,
  converter: None,
}

let date = (options): dateColumn => {
  table: "",
  name: "",
  dbType: #INTEGER,
  size: options.size,
  converter: Some({
    dbToRes: Js.Date.fromString,
    resToDB: Js.Date.toISOString,
  }),
}
