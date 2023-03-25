type converter<'res, 'db> = {
  dbToRes: 'db => 'res,
  resToDB: 'res => 'db,
}

type aggregationType = Count | Sum | Avg | Min | Max

type t<'res, 'db> = {
  table: string,
  name: string,
  dbType: [#VARCHAR | #INTEGER | #REAL | #TEXT],
  nullable: bool,
  size: option<int>,
  converter: option<converter<'res, 'db>>,
  aggregation: option<aggregationType>,
}

type unknownColumn = t<unknown, unknown>

external toUnknownColumn: t<_> => unknownColumn = "%identity"
external toIntColumn: t<_> => t<int, int> = "%identity"
external toFloatColumn: t<_> => t<float, float> = "%identity"
external dictFromRecord: 'a => Js.Dict.t<unknownColumn> = "%identity"
external recordFromDict: Js.Dict.t<unknownColumn> => 'a = "%identity"

module Record = {
  let mapEntries = (record: 'a, f): 'a => {
    record->dictFromRecord->Js.Dict.entries->Js.Array2.map(f)->Js.Dict.fromArray->recordFromDict
  }

  let mapValues = (record: 'a, f): 'a => {
    record->mapEntries(((columnName, column)) => {
      let mapped = f(column)

      (columnName, mapped)
    })
  }
}

type intColumn = t<int, int>
type optionalIntColumn = t<option<int>, Js.Null.t<int>>

type floatColumn = t<float, float>
type optionalFloatColumn = t<option<float>, Js.Null.t<float>>

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

let _float = (nullable, converter, options) => {
  table: "",
  name: "",
  dbType: #REAL,
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

let float: options => floatColumn = _float(false, None)
let optionalFloat: options => optionalFloatColumn = _float(true, Some(nullConverter))

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
