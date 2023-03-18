type t<'columns> = {
  tableName: string,
  tableColumns: 'columns,
}

type tx<'columns, 'a> = {
  tableName: string,
  tableColumns: 'columns,
  patch: 'columns,
  selection: option<QueryBuilder_Expr.t<'a>>,
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

let literal = (value: 'a): Schema.Column.t<'a, _> => Node.Literal(value)->Obj.magic
let skip = Node.Skip->Obj.magic
