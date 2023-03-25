type t<'row, 'error> = string => AsyncResult.t<array<'row>, 'error>

let execute = (
  query: QueryBuilder.Select.tx<array<'row>>,
  getRows: t<'row, 'error>,
): AsyncResult.t<array<'result>, 'error> => {
  let sql = SQL.fromSelectQuery(query)
  let result = getRows(sql)

  AsyncResult.map(result, rows => QueryBuilder_Select_Nest.nestIt(rows, query.projection))
}
