type t<'columns, 'defaults, 'constraints> = {table: Schema.Table.t<'columns, 'constraints>}

type tx<'columns, 'constraints> = {
  table: Schema.Table.t<'columns, 'constraints>,
  values: array<'columns>,
}

let skip = Obj.magic

let insertInto = table => {
  table: table,
}

let values = (q: t<_, 'defaults, _>, values) => {
  {
    table: q.table,
    values: values,
  }
}
