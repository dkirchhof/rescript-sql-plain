type t<'columns> = {tableName: string, tableColumns: 'columns}

type tx<'columns> = {
  tableName: string,
  tableColumns: 'columns,
  values: array<'columns>,
}

let insertInto = (table: Schema.Table.t<'columns, _>) => {
  tableName: table.name,
  tableColumns: table.columns,
}

let values = (q: t<'columns>, values: array<'columns>) => {
  tableName: q.tableName,
  tableColumns: q.tableColumns,
  values,
}
