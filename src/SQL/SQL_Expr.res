let columnToString = (column: Schema.Column.t<_>) => `${column.table}.${column.name}`

let valueToString = (value, converter: option<Schema.Column.converter<_>>) => {
  switch converter {
  | Some(converter) => value->converter.resToDB
  | _ => value
  }->Utils.stringify
}

let simpleExpressionToSQL = (left, right, operator) => {
  let left = Node.fromAny(left)
  let right = Node.fromAny(right)

  switch (left, right) {
  | (Column(leftColumn), Column(rightColumn)) =>
    [columnToString(leftColumn), operator, columnToString(rightColumn)]->Array.joinWith(" ")
  | (Column(leftColumn), Literal(rightLiteral)) =>
    [
      columnToString(leftColumn),
      operator,
      valueToString(rightLiteral, leftColumn.converter),
    ]->Array.joinWith(" ")
  | (Literal(leftLiteral), Column(rightColumn)) =>
    [
      valueToString(leftLiteral, rightColumn.converter),
      operator,
      columnToString(rightColumn),
    ]->Array.joinWith(" ")
  | _ => panic("not implemented")
  }
}

let betweenExpressionToSQL = (left, min, max, negate) => {
  let left = Node.fromAny(left)
  let min = Node.fromAny(min)
  let max = Node.fromAny(max)

  let operatorString = negate ? "NOT BETWEEN" : "BETWEEN"

  switch (left, min, max) {
  | (Column(leftColumn), Literal(minValue), Literal(maxValue)) =>
    [
      columnToString(leftColumn),
      operatorString,
      valueToString(minValue, leftColumn.converter),
      "AND",
      valueToString(maxValue, leftColumn.converter),
    ]->Array.joinWith(" ")
  | _ => panic("not implemented")
  }
}

let inExpressionToSQL = (left, values, negate) => {
  let left = Node.fromAny(left)

  switch left {
  | Column(left) => {
      let valuesString = values->Belt.Array.joinWith(", ", value => {
        let value = Node.fromAny(value)

        switch value {
        | Literal(value) => valueToString(value, left.converter)
        | Column(column) => columnToString(column)
        | _ => panic("not implemented")
        }
      })
      let operatorString = negate ? "NOT IN" : "IN"

      `${columnToString(left)} ${operatorString}(${valuesString})`
    }

  | _ => panic("not implemented")
  }
}

let rec expressionToSQL = expression =>
  switch expression {
  | QueryBuilder.Expr.And(expressions) =>
    `(${Belt.Array.joinWith(expressions, " AND ", expressionToSQL(_))})`
  | QueryBuilder.Expr.Or(expressions) =>
    `(${Belt.Array.joinWith(expressions, " OR ", expressionToSQL(_))})`
  | QueryBuilder.Expr.Equal(left, right) => simpleExpressionToSQL(left, right, "=")
  | QueryBuilder.Expr.NotEqual(left, right) => simpleExpressionToSQL(left, right, "!=")
  | QueryBuilder.Expr.GreaterThan(left, right) => simpleExpressionToSQL(left, right, ">")
  | QueryBuilder.Expr.GreaterThanEqual(left, right) => simpleExpressionToSQL(left, right, ">=")
  | QueryBuilder.Expr.LessThan(left, right) => simpleExpressionToSQL(left, right, "<")
  | QueryBuilder.Expr.LessThanEqual(left, right) => simpleExpressionToSQL(left, right, "<=")
  | QueryBuilder.Expr.Between(left, min, max) => betweenExpressionToSQL(left, min, max, false)
  | QueryBuilder.Expr.NotBetween(left, min, max) => betweenExpressionToSQL(left, min, max, true)
  | QueryBuilder.Expr.In(left, values) => inExpressionToSQL(left, values, false)
  | QueryBuilder.Expr.NotIn(left, values) => inExpressionToSQL(left, values, true)
  }
