type t<'columns, 'constraints> = {
  name: string,
  columns: 'columns,
  constraints: 'constraints,
}

let make = (name, columns: 'a, makeConstraints: 'a => 'b) => {
  let columns: 'a =
    columns
    ->Obj.magic
    ->Js.Dict.entries
    ->Js.Array2.map(((columnName, column: Schema_Column.t<Any.t, Any.t>)) => (
      columnName,
      {...column, table: name, name: columnName},
    ))
    ->Js.Dict.fromArray
    ->Obj.magic

  {name, columns, constraints: makeConstraints(columns)}
}
