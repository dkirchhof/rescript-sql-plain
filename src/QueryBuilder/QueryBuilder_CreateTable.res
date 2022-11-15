type t<'columns, 'constraints> = {table: Schema.Table.t<'columns, 'constraints>}

let createTable = table => {
  table: table,
}
