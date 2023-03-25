type t<'error> = string => AsyncResult.t<unit, 'error>

let execute = (
  query: QueryBuilder.CreateTable.t<_>,
  exec: t<'error>,
): AsyncResult.t<unit, 'error> => {
  let sql = SQL.fromCreateTableQuery(query)

  exec(sql)
}
