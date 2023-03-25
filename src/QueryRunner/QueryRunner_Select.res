let execute = (query: QueryBuilder.Select.tx<'result>, getRows): array<'result> => {
  let sql = SQL.fromSelectQuery(query)
  let rows = getRows(sql)

  Nest.nestIt(rows, query.projection)->Obj.magic
}
