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
  ->Js.Dict.keys
  ->Js.Array2.map(columnName => (columnName, Any.Column({tableAlias, columnName})))
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
      | _=> Some(column, value)
    }
  })
  ->Js.Dict.fromArray
}
