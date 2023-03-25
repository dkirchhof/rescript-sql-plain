type t<'error> = string => AsyncResult.t<unit, 'error>

let execute = (
  query: QueryBuilder.Update.tx<_>,
  exec: t<'error>,
): AsyncResult.t<unit, 'error> => {
  let sql = SQL.fromUpdateQuery(query)

  exec(sql)
}
