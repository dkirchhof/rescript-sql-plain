let ensureArray: array<'a> => array<'a> = %raw(`
  function(maybeArray) {
    if (Array.isArray(maybeArray)) {
      return maybeArray;
    }

    return [maybeArray];
  }
`)

let getStringValuesRec: 'a => array<string> = %raw(`
  function(obj) {
    const values = new Set();

    const rec = current => {
      Object.values(current).forEach(value => {
        if (typeof value === "string") {
          values.add(value);
        } else if (Array.isArray(value)) {
          value.forEach(rec);
        } else if (typeof value === "object") {
          rec(value);
        }
      })
    }

    rec(obj);

    return Array.from(values).sort();
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

let sanitizeValue = value => {
  if Js.Types.test(value, Js.Types.String) {
    `'${value->Obj.magic}'`
  } else {
    value->Obj.magic
  }
}
