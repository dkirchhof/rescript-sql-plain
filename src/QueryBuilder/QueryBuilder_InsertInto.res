type t<'columns> = {table: string}

type tx<'columns> = {
  table: string,
  values: array<'columns>,
}

let insertInto = (table: Schema.Table.t<'columns, _>): t<'columns> => {
  table: table.name,
}

let values = (q: t<'columns>, values: array<'columns>) => {
  table: q.table,
  values,
}
