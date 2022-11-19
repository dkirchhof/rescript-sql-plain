type t<'columns> = {table: string}

type tx<'columns> = {
  table: string,
  values: array<Js.Dict.t<QueryBuilder_Ref.t>>,
}

let insertInto = (table: Schema.Table.t<'columns, _>): t<'columns> => {
  table: table.name,
}

let values = (q: t<'columns>, values: array<'columns>) => {
  let values' = values->Js.Array2.map(Utils.objToRefsDict)

  {
    table: q.table,
    values: values',
  }
}
