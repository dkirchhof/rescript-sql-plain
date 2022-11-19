type t<'columns> = {
  table: string,
  columns: Js.Dict.t<QueryBuilder_Ref.t>,
}

type tx<'columns> = {
  table: string,
  columns: Js.Dict.t<QueryBuilder_Ref.t>,
  patch: Js.Dict.t<QueryBuilder_Ref.t>,
  selection: option<QueryBuilder_Expr.t>,
}

let update = (table: Schema.Table.t<'columns, _>): t<'columns> => {
  table: table.name,
  columns: Utils.columnsToRefsDict(table.columns, None),
}

let set = (q: t<'columns>, patch: 'columns): tx<'columns> => {
  table: q.table,
  columns: q.columns,
  patch: Utils.objToRefsDict(patch),
  selection: None,
}

let where = (q: tx<'columns>, getSelection: 'columns => QueryBuilder_Expr.t) => {
  let selection = getSelection(q.columns->Obj.magic)

  {...q, selection: Some(selection)}
}
