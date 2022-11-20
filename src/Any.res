type rec t =
  | Skip
  | Number(float)
  | String(string)
  | Date(Js.Date.t)
  | Column(columnOption)
  | Array(array<t>)
  | Obj(t)

and columnOption = {
  tableAlias: option<string>,
  columnName: string,
  converter: option<t => t>,
}

let makeSkip = () => Skip
let makeNumber = value => Number(value)
let makeString = value => String(value)
let makeDate = value => Date(value)
/* let makeColumn = value => Column(value) */
let makeArray = value => Array(value)
let makeObj = value => Obj(value)

let make: 'a => t = %raw(`
  function(value) {
    if (value === undefined) {
      return skip;
    }

    if (typeof value === "number") {
      return makeNumber(value);
    }

    if (typeof value === "string") {
      return makeString(value);
    }

    if (value instanceof Date) {
      return makeDate(value);
    }

    if (Array.isArray(value)) {
      return makeArray(value);
    }

    if (typeof value === "object") {
      if (value.TAG !== undefined) {
        return value;
      }

      return makeObj(value);
    }

    throw new Error("Can't find a mapper for " + value + ".");
  }
`)

let makeColumn = (tableAlias, columnName, converter) => Column({
  tableAlias,
  columnName,
  converter: converter->Obj.magic,
})
