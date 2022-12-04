open StringBuilder

let withAggregation = (string, aggregation) => {
  open Schema.Column

  switch aggregation {
  | None => string
  | Some(Count) => `COUNT(${string})`
  | Some(Sum) => `SUM(${string})`
  | Some(Avg) => `AVG(${string})`
  | Some(Min) => `MIN(${string})`
  | Some(Max) => `MAX(${string})`
  }
}

let projectionToSQL = projection => {
  let columns =
    make()
    ->addM(
      0,
      projection
      ->Node.dictFromRecord
      ->Js.Dict.entries
      ->Js.Array2.map(((alias, node)) => {
        switch node {
        | Node.Column(column) =>
          withAggregation(`${column.table}.${column.name}`, column.aggregation) ++ ` AS ${alias}`
        | _ => Js.Exn.raiseError("not implemented yet")
        }
      }),
    )
    ->build(", ")

  `SELECT ${columns}`
}

let fromToSQL = (source: QueryBuilder.Select.source) => `FROM ${source.name} AS ${source.alias}`

let joinTypeToSQL = (joinType: QueryBuilder.Select.joinType) =>
  switch joinType {
  | Inner => "INNER JOIN"
  | Left => "LEFT JOIN"
  }

let joinToSQL = (join: QueryBuilder.Select.join) => {
  let joinTypeString = joinTypeToSQL(join.joinType)
  let tableName = join.source.name
  let tableAlias = join.source.alias

  let (leftColumn, rightColumn) = join.on
  let exprString = `${leftColumn.table}.${leftColumn.name} = ${rightColumn.table}.${rightColumn.name}`

  `${joinTypeString} ${tableName} AS ${tableAlias} ON ${exprString}`
}

let joinsToSQL = joins => {
  joins->Js.Array2.map(joinToSQL)
}

let selectionToSQL = selection => {
  selection->Belt.Option.map(expr => `WHERE ${SQL_Expr.expressionToSQL(expr)}`)
}

let havingToSQL = having => {
  having->Belt.Option.map(expr => `HAVING ${SQL_Expr.expressionToSQL(expr)}`)
}

let groupToSQL = (column: Schema.Column.unknownColumn) => {
  `${column.table}.${column.name}`
}

let groupByToSQL = groupBy => {
  groupBy->Belt.Option.map(group => `GROUP BY ${group->Belt.Array.joinWith(", ", groupToSQL)}`)
}

let directionToSQL = (direction: QueryBuilder.Select.direction) =>
  switch direction {
  | Asc => "ASC"
  | Desc => "DESC"
  }

let orderToSQL = (order: QueryBuilder.Select.order) => {
  let direction = order.direction->directionToSQL

  `${order.column.table}.${order.column.name} ${direction}`
}

let orderByToSQL = orderBy => {
  orderBy->Belt.Option.map(order => `ORDER BY ${order->Belt.Array.joinWith(", ", orderToSQL)}`)
}

let limitToSQL = limit => {
  limit->Belt.Option.map(l => `LIMIT ${Belt.Int.toString(l)}`)
}

let offsetToSQL = offset => {
  offset->Belt.Option.map(o => `OFFSET ${Belt.Int.toString(o)}`)
}

let fromSelectQuery = (q: QueryBuilder.Select.tx<_>) => {
  make()
  ->addS(0, projectionToSQL(q.projection))
  ->addS(0, fromToSQL(q.from))
  ->addM(0, joinsToSQL(q.joins))
  ->addSO(0, selectionToSQL(q.selection))
  ->addSO(0, groupByToSQL(q.groupBy))
  ->addSO(0, havingToSQL(q.having))
  ->addSO(0, orderByToSQL(q.orderBy))
  ->addSO(0, limitToSQL(q.limit))
  ->addSO(0, offsetToSQL(q.offset))
  ->build("\n")
}
