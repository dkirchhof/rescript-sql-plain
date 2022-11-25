open StringBuilder

let fromInsertQuery = (q: QueryBuilder.Insert.tx<_>) => {
  let columns = SQL_Common.getNonSkippedColumns(~record=q.values[0], ~columns=q.tableColumns)
  let columnsString = columns->Belt.Array.joinWith(", ", column => column.name)

  let rowStrings = q.values->Js.Array2.map(row => {
    let converted = SQL_Common.convertRecordToStringDict(~record=row, ~columns)
    let rowString = converted->Js.Dict.values->Js.Array2.joinWith(", ")

    `(${rowString})`
  })

  let valuesString = make()->addM(2, rowStrings)->build(",\n")

  make()
  ->addS(0, `INSERT INTO ${q.tableName}(${columnsString}) VALUES`)
  ->addS(0, valuesString)
  ->build("\n")
}
