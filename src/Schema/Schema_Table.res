type t<'columns, 'constraints> = {
  name: string,
  columns: 'columns,
  constraints: 'constraints,
}

let make = (name, columns: 'columns, makeConstraints: 'columns => 'constraints) => {
  let columns = columns->Schema_Column.Record.mapEntries(((columnName, column)) => {
    let column = {...column, table: name, name: columnName}

    (columnName, column)
  })

  {name, columns, constraints: makeConstraints(columns)}
}
