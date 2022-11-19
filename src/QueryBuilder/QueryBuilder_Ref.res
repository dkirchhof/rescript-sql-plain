/* type t = */
/*   | Undefined */
/*   | NumericLiteral(float) */
/*   | StringLiteral(string) */
/*   | Column({columnName: string, tableAlias: option<string>}) */

/* let make = value => { */
/*   let x = Any.make(value) */

/*   switch x { */
/*   | Undefined => Undefined */
/*   | Number(value) => NumericLiteral(value) */
/*   | String(value) => StringLiteral(value) */
/*   | Ref(value) => value->Obj.magic */
/*   | _ => Js.Exn.raiseError("Can't make ref from this type.") */
/*   } */
/* } */

/* let makeFromAnyType = (value: Any.t) => { */
/*   switch value { */
/*   | Undefined => Undefined */
/*   | Number(value) => NumericLiteral(value) */
/*   | String(value) => StringLiteral(value) */
/*   | Ref(value) => value->Obj.magic */
/*   | _ => Js.Exn.raiseError("Can't make ref from this type.") */
/*   } */
/* } */
