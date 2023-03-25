type t<'error> = string => AsyncResult.t<unit, 'error>

let execute = (
  query: QueryBuilder.Insert.tx<_>,
  exec: t<'error>,
): AsyncResult.t<unit, 'error> => {
  let sql = SQL.fromInsertQuery(query)

  exec(sql)
}
