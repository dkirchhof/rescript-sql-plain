type t<'columns> = {
  tableName: string,
  tableColumns: 'columns,
}

type tx<'columns> = {
  tableName: string,
  tableColumns: 'columns,
  patch: 'columns,
  selection: option<QueryBuilder_Expr.t>,
}

let update = (table: Schema.Table.t<_>) => {
  tableName: table.name,
  tableColumns: table.columns,
}

let set = (q: t<_>, patch: 'columns) => {
  tableName: q.tableName,
  tableColumns: q.tableColumns,
  patch,
  selection: None,
}

let where = (q, getSelection) => {
  let selection = getSelection(q.tableColumns)

  {...q, selection: Some(selection)}
}
