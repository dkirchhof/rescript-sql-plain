type t<'error> = string => AsyncResult.t<unit, 'error>

let execute = (
  query: QueryBuilder.Delete.t<_>,
  exec: t<'error>,
): AsyncResult.t<unit, 'error> => {
  let sql = SQL.fromDeleteQuery(query)

  exec(sql)
}
