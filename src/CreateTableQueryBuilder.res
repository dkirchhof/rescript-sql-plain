type t<'a, 'b> = {table: Schema.Table.t<'a, 'b>}

let createTable = table => {
  table: table,
}
