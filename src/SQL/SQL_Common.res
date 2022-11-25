let getNonSkippedColumns = (~record, ~columns) => {
  record
  ->Node.dictFromRecord
  ->Js.Dict.entries
  ->Js.Array2.filter(((_, value)) => value !== Node.Skip)
  ->Js.Array2.map(((columnName, _)) =>
    columns->Node.dictFromRecord->Js.Dict.unsafeGet(columnName)->Node.getColumnExn
  )
}

let convertIfNeccessary = (value, targetColumn: Schema_Column.t<_>) => {
  switch targetColumn.converter {
  | Some(converter) => value->converter.resToDB
  | _ => value
  }
}

let convertRecordToStringDict = (~record, ~columns: array<Schema_Column.t<_>>) => {
  columns
  ->Js.Array2.map(column => {
    let value = record->Node.dictFromRecord->Js.Dict.unsafeGet(column.name)

    let valueString = switch value {
    | Node.Literal(value) => convertIfNeccessary(value, column)->Utils.stringify
    | _ => Js.Exn.raiseError("not implemented yet")
    }

    (column.name, valueString)
  })
  ->Js.Dict.fromArray
}

let simpleExpressionToSQL = (left, right, operator) => {
  let column = left->Node.getColumnExn

  let valueString = switch right {
  | Node.Literal(value) => convertIfNeccessary(value, column)->Utils.stringify
  | Node.Column(column) => `${column.table}.${column.name}`
  | _ => Js.Exn.raiseError("not implemented yet")
  }

  `${column.table}.${column.name} ${operator} ${valueString}`
}

let betweenExpressionToSQL = (column, min, max, negate) => {
  let column = column->Node.getColumnExn

  let minString = switch min {
  | Node.Literal(value) => convertIfNeccessary(value, column)->Utils.stringify
  | Node.Column(column) => `${column.table}.${column.name}`
  | _ => Js.Exn.raiseError("not implemented yet")
  }

  let maxString = switch max {
  | Node.Literal(value) => convertIfNeccessary(value, column)->Utils.stringify
  | Node.Column(column) => `${column.table}.${column.name}`
  | _ => Js.Exn.raiseError("not implemented yet")
  }

  let operatorString = negate ? "NOT BETWEEN" : "BETWEEN"

  `${column.table}.${column.name} ${operatorString} ${minString} AND ${maxString}`
}

let inExpressionToSQL = (column, values, negate) => {
  let column = column->Node.getColumnExn

  let valuesString = values->Belt.Array.joinWith(", ", node => {
    switch node {
    | Node.Literal(value) => convertIfNeccessary(value, column)->Utils.stringify
    | Node.Column(column) => `${column.table}.${column.name}`
    | _ => Js.Exn.raiseError("not implemented yet")
    }
  })

  let operatorString = negate ? "NOT IN" : "IN"

  `${column.table}.${column.name} ${operatorString}(${valuesString})`
}

let rec expressionToSQL = expression =>
  switch expression {
  | QueryBuilder.Expr.And(expressions) =>
    `(${Belt.Array.joinWith(expressions, " AND ", expressionToSQL(_))})`
  | QueryBuilder.Expr.Or(expressions) =>
    `(${Belt.Array.joinWith(expressions, " OR ", expressionToSQL(_))})`
  | QueryBuilder.Expr.Equal(left, right) => simpleExpressionToSQL(left, right, "=")
  | QueryBuilder.Expr.NotEqual(left, right) => simpleExpressionToSQL(left, right, "<>")
  | QueryBuilder.Expr.GreaterThan(left, right) => simpleExpressionToSQL(left, right, ">")
  | QueryBuilder.Expr.GreaterThanEqual(left, right) => simpleExpressionToSQL(left, right, ">=")
  | QueryBuilder.Expr.LessThan(left, right) => simpleExpressionToSQL(left, right, "<")
  | QueryBuilder.Expr.LessThanEqual(left, right) => simpleExpressionToSQL(left, right, "<=")
  | QueryBuilder.Expr.Between(column, min, max) => betweenExpressionToSQL(column, min, max, false)
  | QueryBuilder.Expr.NotBetween(column, min, max) => betweenExpressionToSQL(column, min, max, true)
  | QueryBuilder.Expr.In(column, values) => inExpressionToSQL(column, values, false)
  | QueryBuilder.Expr.NotIn(column, values) => inExpressionToSQL(column, values, true)
  }
