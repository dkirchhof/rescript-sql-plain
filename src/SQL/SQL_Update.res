open StringBuilder

let fromUpdateQuery = (q: QueryBuilder.Update.tx<_>) => {
  let columns = SQL_Common.getNonSkippedColumns(~record=q.patch, ~columns=q.tableColumns)
  let convertedPatch = SQL_Common.convertRecordToStringDict(~record=q.patch, ~columns)

  let patchString =
    convertedPatch
    ->Js.Dict.entries
    ->Js.Array2.map(((columnName, value)) => `${columnName} = ${value}`)
    ->Js.Array2.joinWith(", ")

  make()
  ->addS(0, `UPDATE ${q.tableName}`)
  ->addS(2, `SET ${patchString}`)
  ->addSO(2, q.selection->Belt.Option.map(expr => `WHERE ${SQL_Common.expressionToSQL(expr)}`))
  ->build("\n")
}
