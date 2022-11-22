type t<'columns, 'constraints> = {
  name: string,
  columns: 'columns,
  constraints: 'constraints,
}

let make = (name, columns: 'columns, makeConstraints: 'columns => 'constraints) => {
  let columns: 'columns =
    columns
    ->Node.dictFromRecord
    ->Js.Dict.entries
    ->Js.Array2.map(((columnName, node)) => {
      let column = switch node {
        | Node.Column(column) => Node.Column({...column, table: name, name: columnName})
        | _ => Js.Exn.raiseError("This value should be a Column.")
      }
      (columnName, column)
    })
    ->Js.Dict.fromArray
    ->Obj.magic

  {name, columns, constraints: makeConstraints(columns)}
}
