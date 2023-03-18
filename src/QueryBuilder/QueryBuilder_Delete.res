type t<'columns, 'a> = {
  tableName: string,
  tableColumns: 'columns,
  selection: option<QueryBuilder_Expr.t<'a>>,
}

let deleteFrom = (table: Schema.Table.t<_>) => {
  tableName: table.name,
  tableColumns: table.columns,
  selection: None,
}

let where = (q, getSelection) => {
  let selection = getSelection(q.tableColumns)

  {...q, selection: Some(selection)}
}
