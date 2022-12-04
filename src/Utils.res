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

let stringify: 'a => string = %raw(`
  function(value) {
    if (value === null) {
      return "NULL";
    }

    if (typeof value === "string") {
      return "'" + value.replaceAll("'", "''") + "'";
    }

    return value.toString();
  }
`)

let mapEntries = (record: 'a, f): 'a => {
  record->Obj.magic->Js.Dict.entries->Js.Array2.map(f)->Js.Dict.fromArray->Obj.magic
}
