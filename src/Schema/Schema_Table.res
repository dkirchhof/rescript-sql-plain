type t<'columns, 'constraints> = {
  name: string,
  columns: 'columns,
  constraints: 'constraints,
}

let make = (name, columns: 'columns, makeConstraints: 'columns => 'constraints) => {
  let columns: 'columns =
    columns
    ->ColumnOrLiteral.dictFromRecord
    ->Js.Dict.entries
    ->Js.Array2.map(((columnName, col)) => {
      let col = switch col {
        | ColumnOrLiteral.Column(column) => ColumnOrLiteral.Column({...column, table: name, name: columnName})
        | _ => Js.Exn.raiseError("This value should be a Column.")
      }
      (columnName, col)
    })
    ->Js.Dict.fromArray
    ->Obj.magic

  {name, columns, constraints: makeConstraints(columns)}
}
