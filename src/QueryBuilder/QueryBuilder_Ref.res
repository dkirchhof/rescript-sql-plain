type t =
  | Undefined
  | NumericLiteral(float)
  | StringLiteral(string)
  | Column({columnName: string, tableAlias: option<string>})

let isRef: 'a => bool = %raw(`
  function(obj) {
    return obj.TAG !== undefined;
  }
`)

let make = value => {
  let any = value->Obj.magic

  if Js.Types.test(any, Js.Types.Number) {
    NumericLiteral(any)
  } else if Js.Types.test(any, Js.Types.String) {
    StringLiteral(any)
  } else if isRef(any) {
    any
  } else {
    Js.Exn.raiseError("Can't make a ref from this value.")
  }
}
