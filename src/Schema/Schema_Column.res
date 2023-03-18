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
external dictFromRecord: 'a => Js.Dict.t<unknownColumn> = "%identity"
external recordFromDict: Js.Dict.t<unknownColumn> => 'a = "%identity"
external fromAny: 'a => t<_, _> = "%identity"

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

type options = {size?: int}

let _varchar = (nullable, converter, options) => Obj.magic({
  table: "",
  name: "",
  dbType: #VARCHAR,
  nullable,
  size: options.size,
  converter,
  aggregation: None,
})

let _text = (nullable, converter, options) => Obj.magic({
  table: "",
  name: "",
  dbType: #TEXT,
  nullable,
  size: options.size,
  converter,
  aggregation: None,
})

let _integer = (nullable, converter, options) => Obj.magic({
  table: "",
  name: "",
  dbType: #INTEGER,
  nullable,
  size: options.size,
  converter,
  aggregation: None,
})

let _float = (nullable, converter, options) => Obj.magic({
  table: "",
  name: "",
  dbType: #REAL,
  nullable,
  size: options.size,
  converter,
  aggregation: None,
})

let _date = (nullable, converter, options) => Obj.magic({
  table: "",
  name: "",
  dbType: #INTEGER,
  nullable,
  size: options.size,
  converter,
  aggregation: None,
})

let nullConverter = {
  dbToRes: Js.Null.toOption,
  resToDB: Js.Null.fromOption,
}

let varchar: options => string = _varchar(false, None)
let optionalVarchar: options => option<string> = _varchar(true, Some(nullConverter))

let text: options => string = _text(false, None)
let optionalText: options => option<string> = _text(true, Some(nullConverter))

let integer: options => int = _integer(false, None)
let optionalInteger: options => option<int> = _integer(true, Some(nullConverter))

let float: options => float = _float(false, None)
let optionalFloat: options => option<float> = _float(true, Some(nullConverter))

let date: options => Js.Date.t = _date(
  false,
  Some({
    dbToRes: Js.Date.fromString,
    resToDB: Js.Date.toISOString,
  }),
)

let optionalDate: options => option<Js.Date.t> = _date(
  true,
  Some({
    dbToRes: value => value->Js.Null.toOption->Belt.Option.map(Js.Date.fromString),
    resToDB: value => value->Belt.Option.map(Js.Date.toISOString)->Js.Null.fromOption,
  }),
)
