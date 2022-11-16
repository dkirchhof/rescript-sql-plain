type t<'columns> = {
  table: string,
  columns: Js.Dict.t<string>,
}

type tx<'columns> = {
  table: string,
  columns: Js.Dict.t<string>,
  patch: 'columns,
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

let update = (table: Schema.Table.t<'columns, _>): t<'columns> => {
  table: table.name,
  columns: mapColumns(table.columns),
}

let set = (q: t<'columns>, patch: 'columns) => {
  table: q.table,
  columns: q.columns,
  patch,
  selection: None,
}

let where = (q: tx<'columns>, getSelection: 'columns => QueryBuilder_Expr.t) => {
  let selection = getSelection(q.columns->Obj.magic)

  {...q, selection: Some(selection)}
}
