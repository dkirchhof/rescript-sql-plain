let simpleExpressionToSQL = (column, right, operator) => {
  let valueString = switch right {
  | Node.Literal(value) => SQL_Common.convertIfNeccessary(value, column)->Utils.stringify
  | Node.Column(column) => `${column.table}.${column.name}`
  | Node.Query(sql) => `(${sql->Obj.magic})`
  | _ => Js.Exn.raiseError("not implemented yet")
  }

  `${column.table}.${column.name} ${operator} ${valueString}`
}

let betweenExpressionToSQL = (column, min: Node.unknownNode, max: Node.unknownNode, negate) => {
  let minString = switch min {
  | Node.Literal(value) => SQL_Common.convertIfNeccessary(value, column)->Utils.stringify
  | Node.Column(column) => `${column.table}.${column.name}`
  | Node.Query(sql) => `(${sql->Obj.magic})`
  | _ => Js.Exn.raiseError("not implemented yet")
  }

  let maxString = switch max {
  | Node.Literal(value) => SQL_Common.convertIfNeccessary(value, column)->Utils.stringify
  | Node.Column(column) => `${column.table}.${column.name}`
  | Node.Query(sql) => `(${sql->Obj.magic})`
  | _ => Js.Exn.raiseError("not implemented yet")
  }

  let operatorString = negate ? "NOT BETWEEN" : "BETWEEN"

  `${column.table}.${column.name} ${operatorString} ${minString} AND ${maxString}`
}

let inExpressionToSQL = (column, values: array<Node.unknownNode>, negate) => {
  let valuesString = values->Belt.Array.joinWith(", ", node => {
    switch node {
    | Node.Literal(value) => SQL_Common.convertIfNeccessary(value, column)->Utils.stringify
    | Node.Column(column) => `${column.table}.${column.name}`
    | Node.Query(sql) => `${sql->Obj.magic}`
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
  | QueryBuilder.Expr.NotEqual(left, right) => simpleExpressionToSQL(left, right, "!=")
  | QueryBuilder.Expr.GreaterThan(left, right) => simpleExpressionToSQL(left, right, ">")
  | QueryBuilder.Expr.GreaterThanEqual(left, right) => simpleExpressionToSQL(left, right, ">=")
  | QueryBuilder.Expr.LessThan(left, right) => simpleExpressionToSQL(left, right, "<")
  | QueryBuilder.Expr.LessThanEqual(left, right) => simpleExpressionToSQL(left, right, "<=")
  | QueryBuilder.Expr.Between(column, min, max) => betweenExpressionToSQL(column, min, max, false)
  | QueryBuilder.Expr.NotBetween(column, min, max) => betweenExpressionToSQL(column, min, max, true)
  | QueryBuilder.Expr.In(column, values) => inExpressionToSQL(column, values, false)
  | QueryBuilder.Expr.NotIn(column, values) => inExpressionToSQL(column, values, true)
  }
