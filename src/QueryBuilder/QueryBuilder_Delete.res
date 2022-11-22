type t<'columns> = {
  tableName: string,
  tableColumns: 'columns,
  selection: option<QueryBuilder_Expr.t>,
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
