@send external replaceAll: (string, string, string) => string = "replaceAll"

let ensureArray: 'a => array<'a> = %raw(`
  function(maybeArray) {
    if (Array.isArray(maybeArray)) {
      return maybeArray;
    }

    return [maybeArray];
  }
`)

module ItemOrArray = {
  type t<'t> = Item('t) | Array(array<'t>)

  let concat = (t, newArray) => {
    switch t {
    | Item(item) => Js.Array2.concat([item], newArray)->Array
    | Array(oldArray) => Js.Array2.concat(oldArray, newArray)->Array
    }
  }

  let apply = (t, fn) =>
    switch t {
    | Item(item) => fn(item->Obj.magic)
    | Array(array) => fn(array->Obj.magic)
    }
}

let columnsToAnyDict = (columns, tableAlias) => {
  columns
  ->Obj.magic
  ->Js.Dict.values
  ->Js.Array2.map((column: Schema_Column.t<_>) => (
    column.name,
    Any.makeColumn(tableAlias, column.name, column.converter),
  ))
  ->Js.Dict.fromArray
}

let objToRefsDict = obj => {
  obj
  ->Obj.magic
  ->Js.Dict.entries
  ->Belt.Array.keepMap(((column, value)) => {
    let value = Any.make(value)

    switch value {
    | Skip => None
    | _ => Some(column, value)
    }
  })
  ->Js.Dict.fromArray
}

let stringify: 'a => string = %raw(`
  function(value) {
    if (typeof value === "string") {
      return "'" + value.replaceAll("'", "''") + "'";
    }

    return value.toString();
  }
`)

let mapEntries = (record: 'a, f): 'a => {
  record->Obj.magic->Js.Dict.entries->Js.Array2.map(f)->Js.Dict.fromArray->Obj.magic
}
