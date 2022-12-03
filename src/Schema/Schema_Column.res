type converter<'res, 'db> = {
  dbToRes: 'db => 'res,
  resToDB: 'res => 'db,
}

type aggregationType = Count | Sum | Avg | Min | Max

type t<'res, 'db> = {
  table: string,
  name: string,
  dbType: [#VARCHAR | #INTEGER | #TEXT],
  nullable: bool,
  size: option<int>,
  converter: option<converter<'res, 'db>>,
  aggregation: option<aggregationType>,
}

type intColumn = t<int, int>
type optionalIntColumn = t<option<int>, Js.Null.t<int>>

type stringColumn = t<string, string>
type optionalStringColumn = t<option<string>, Js.Null.t<string>>

type dateColumn = t<Js.Date.t, string>
type optionalDateColumn = t<option<Js.Date.t>, Js.Null.t<string>>

type options = {size?: int}

let _varchar = (nullable, converter, options) => {
  table: "",
  name: "",
  dbType: #VARCHAR,
  nullable,
  size: options.size,
  converter,
  aggregation: None,
}

let _text = (nullable, converter, options) => {
  table: "",
  name: "",
  dbType: #TEXT,
  nullable,
  size: options.size,
  converter,
  aggregation: None,
}

let _integer = (nullable, converter, options) => {
  table: "",
  name: "",
  dbType: #INTEGER,
  nullable,
  size: options.size,
  converter,
  aggregation: None,
}

let _date = (nullable, converter, options) => {
  table: "",
  name: "",
  dbType: #INTEGER,
  nullable,
  size: options.size,
  converter,
  aggregation: None,
}

let nullConverter = {
  dbToRes: Js.Null.toOption,
  resToDB: Js.Null.fromOption,
}

let varchar: options => stringColumn = _varchar(false, None)
let optionalVarchar: options => optionalStringColumn = _varchar(true, Some(nullConverter))

let text: options => stringColumn = _text(false, None)
let optionalText: options => optionalStringColumn = _text(true, Some(nullConverter))

let integer: options => intColumn = _integer(false, None)
let optionalInteger: options => optionalIntColumn = _integer(true, Some(nullConverter))

let date: options => dateColumn = _date(
  false,
  Some({
    dbToRes: Js.Date.fromString,
    resToDB: Js.Date.toISOString,
  }),
)

let optionalDate: options => optionalDateColumn = _date(
  true,
  Some({
    dbToRes: value => value->Js.Null.toOption->Belt.Option.map(Js.Date.fromString),
    resToDB: value => value->Belt.Option.map(Js.Date.toISOString)->Js.Null.fromOption,
  }),
)
