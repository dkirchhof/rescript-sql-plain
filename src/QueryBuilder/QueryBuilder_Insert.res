type t<'columns> = {tableName: string, tableColumns: 'columns}

type tx<'columns> = {
  tableName: string,
  tableColumns: 'columns,
  values: array<'columns>,
}

let insertInto = (table: Schema.Table.t<_>) => {
  tableName: table.name,
  tableColumns: table.columns,
}

let values = (q: t<_>, values) => {
  tableName: q.tableName,
  tableColumns: q.tableColumns,
  values,
}

let literal = (value: 'a): Schema.Column.t<'a, _> => Node.Literal(value)->Obj.magic
let skip = Node.Skip->Obj.magic
