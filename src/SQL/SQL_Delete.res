open StringBuilder

let fromDeleteQuery = (q: QueryBuilder.Delete.t<_>) => {
  make()
  ->addS(0, `DELETE FROM ${q.tableName}`)
  ->addSO(2, q.selection->Belt.Option.map(expr => `WHERE ${SQL_Common.expressionToSQL(expr)}`))
  ->build("\n")
}
