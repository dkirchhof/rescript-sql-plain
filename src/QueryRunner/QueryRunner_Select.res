let execute = (query, getRows) => {
  let sql = SQL.fromSelectQuery(query)
  let rows = getRows(sql)

  Nest.nestIt(rows, query.projection)
}
