type t<'columns> = {
  table: string,
  columns: Js.Dict.t<QueryBuilder_Ref.t>,
  selection: option<QueryBuilder_Expr.t>,
}

let deleteFrom = (table: Schema.Table.t<'columns, _>): t<'columns> => {
  table: table.name,
  columns: Utils.columnsToRefsDict(table.columns, None),
  selection: None,
}

let where = (q: t<'columns>, getSelection: 'columns => QueryBuilder_Expr.t) => {
  let selection = getSelection(q.columns->Obj.magic)

  {...q, selection: Some(selection)}
}
