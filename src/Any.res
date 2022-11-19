type columnOption = {
  tableAlias: option<string>,
  columnName: string,
}

@deriving(accessors)
type rec t =
  | Skip
  | Number(float)
  | String(string)
  | Column(columnOption)
  | Array(array<t>)
  | Obj(t)

let make: 'a => t = %raw(`
  function(value) {
    if (value === undefined) {
      return skip;
    }

    if (typeof value === "number") {
      return number(value);
    }

    if (typeof value === "string") {
      return string(value);
    }

    if (Array.isArray(value)) {
      return array(value);
    }

    if (typeof value === "object") {
      if (value.TAG !== undefined) {
        return value;
      }

      return obj(value);
    }

    throw new Error("Can't find a mapper for " + value + ".");
  }
`)
