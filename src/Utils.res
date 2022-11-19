external objToDictUnsafe: 'a => Js.Dict.t<'b> = "%identity"

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

let columnsToRefsDict = (columns, tableAlias) => {
  columns
  ->objToDictUnsafe
  ->Js.Dict.keys
  ->Js.Array2.map(columnName => (columnName, QueryBuilder_Ref.Column({columnName, tableAlias})))
  ->Js.Dict.fromArray
}

let objToRefsDict = obj => {
  obj
  ->objToDictUnsafe
  ->Js.Dict.entries
  ->Belt.Array.keepMap(((column, value)) =>
    if value === Js.undefined {
      None
    } else {
      Some((column, QueryBuilder_Ref.make(value)))
    }
  )
  ->Js.Dict.fromArray
}
