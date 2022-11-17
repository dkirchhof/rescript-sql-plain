type t<'columns> = {
  table: string,
  columns: Js.Dict.t<string>,
  selection: option<QueryBuilder_Expr.t>,
}

%%private(
  let mapColumns = columns => {
    columns
    ->Obj.magic
    ->Js.Dict.keys
    ->Js.Array2.map(column => (column, column))
    ->Js.Dict.fromArray
  }
)

let deleteFrom = (table: Schema.Table.t<'columns, _>): t<'columns> => {
  table: table.name,
  columns: mapColumns(table.columns),
  selection: None,
}

let where = (q: t<'columns>, getSelection: 'columns => QueryBuilder_Expr.t) => {
  let selection = getSelection(q.columns->Obj.magic)

  {...q, selection: Some(selection)}
}
