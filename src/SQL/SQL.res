open StringBuilder

let convertIfNeccessary = (value, targetColumn: Schema_Column.t<_>) => {
  switch targetColumn.converter {
  | Some(converter) => value->converter.resToDB
  | _ => value
  }
}

let getNonSkippedColumnNames = record => {
  record
  ->Node.dictFromRecord
  ->Js.Dict.entries
  ->Js.Array2.filter(((_, value)) => value !== Node.Skip)
  ->Js.Array2.map(fst)
}

let getNonSkippedColumns = (~record, ~columns) => {
  record
  ->Node.dictFromRecord
  ->Js.Dict.entries
  ->Js.Array2.filter(((_, value)) => value !== Node.Skip)
  ->Js.Array2.map(((columnName, _)) =>
    columns->Node.dictFromRecord->Js.Dict.unsafeGet(columnName)->Node.getColumnExn
  )
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

%%private(
  let fkStrategyToSQL = s =>
    switch s {
    | Schema.Constraint.FKStrategy.Cascade => "CASCADE"
    | Schema.Constraint.FKStrategy.NoAction => "NO ACTION"
    | Schema.Constraint.FKStrategy.Restrict => "RESTRICT"
    | Schema.Constraint.FKStrategy.SetDefault => "SET DEFAULT"
    | Schema.Constraint.FKStrategy.SetNull => "SET NULL"
    }

  let constraintToSQL = (name, cnstraint) =>
    switch cnstraint {
    | Schema.Constraint.PrimaryKey(nodes) => {
        let columnsString = nodes->Belt.Array.joinWith(", ", node =>
          switch node {
          | Node.Column(column) => column.name
          | _ => Js.Exn.raiseError("This value should be a columns.")
          }
        )

        `CONSTRAINT ${name} PRIMARY KEY(${columnsString})`
      }

    | ForeignKey(ownColumn, foreignColumn, onUpdate, onDelete) =>
      switch (ownColumn, foreignColumn) {
      | (Node.Column(ownColumn), Node.Column(foreignColumn)) => {
          let references = `REFERENCES ${foreignColumn.table}(${foreignColumn.name})`
          let onUpdate = `ON UPDATE ${fkStrategyToSQL(onUpdate)}`
          let onDelete = `ON DELETE ${fkStrategyToSQL(onDelete)}`

          `CONSTRAINT ${name} FOREIGN KEY(${ownColumn.name}) ${references} ${onUpdate} ${onDelete}`
        }

      | _ => Js.Exn.raiseError("ownColumn and foreignColumn should be columns.")
      }
    }

  /* let expressionToSQL = expr => */
  /* switch expr { */
  /* | QueryBuilder.Expr.Equal(left, right) => `${left->anyToSQL} = ${right->anyToSQL}` */
  /* } */

  let sourceToSQL = (source: QueryBuilder.Select.source) => `${source.name} AS ${source.alias}`

  let joinTypeToSQL = (joinType: QueryBuilder.Select.joinType) =>
    switch joinType {
    | Inner => "INNER JOIN"
    | Left => "LEFT JOIN"
    }

  let joinToSQL = (join: QueryBuilder.Select.join) => {
    let joinTypeString = joinTypeToSQL(join.joinType)
    let tableName = join.source.name
    let tableAlias = join.source.alias
    let exprString = expressionToSQL(join.on)

    `${joinTypeString} ${tableName} AS ${tableAlias} ON ${exprString}`
  }
)

let fromCreateTableQuery = (q: QueryBuilder.CreateTable.t<_>) => {
  let innerString =
    make()
    ->addM(
      2,
      q.table.columns
      ->Node.dictFromRecord
      ->Js.Dict.entries
      ->Js.Array2.map(((name: string, node)) =>
        switch node {
        | Node.Column(column) =>
          let sizeString = switch column.size {
          | Some(size) => `(${size->Belt.Int.toString})`
          | None => ""
          }

          `${name} ${(column.dbType :> string)}${sizeString} NOT NULL`
        | _ => Js.Exn.raiseError("This node should be a column.")
        }
      ),
    )
    ->addM(
      2,
      q.table.constraints
      ->Obj.magic
      ->Js.Dict.entries
      ->Js.Array2.map(((name, cnstraint: Schema.Constraint.t)) => constraintToSQL(name, cnstraint)),
    )
    ->build(",\n")

  make()->addS(0, `CREATE TABLE ${q.table.name} (`)->addS(0, innerString)->addS(0, `)`)->build("\n")
}

let fromSelectQuery = (q: QueryBuilder.Select.tx<_>) => {
  let projectionString =
    make()
    ->addM(
      0,
      q.projection
      ->Node.dictFromRecord
      ->Js.Dict.entries
      ->Js.Array2.map(((alias, node)) => {
        switch node {
        | Column(column) => `${column.table}.${column.name} AS ${alias}`
        | _ => Js.Exn.raiseError("not implemented yet")
        }
      }),
    )
    ->build(", ")

  make()
  ->addS(0, `SELECT ${projectionString}`)
  ->addS(0, `FROM ${sourceToSQL(q.from)}`)
  ->addM(0, q.joins->Js.Array2.map(joinToSQL))
  ->addSO(0, q.selection->Belt.Option.map(expr => `WHERE ${expressionToSQL(expr)}`))
  ->build("\n")
}

let fromInsertIntoQuery = (q: QueryBuilder.Insert.tx<_>) => {
  let columns = getNonSkippedColumns(~record=q.values[0], ~columns=q.tableColumns)
  let columnsString = columns->Belt.Array.joinWith(", ", column => column.name)

  let rowStrings = q.values->Js.Array2.map(row => {
    let converted = convertRecordToStringDict(~record=row, ~columns)
    let rowString = converted->Js.Dict.values->Js.Array2.joinWith(", ")

    `(${rowString})`
  })

  let valuesString = make()->addM(2, rowStrings)->build(",\n")

  make()
  ->addS(0, `INSERT INTO ${q.tableName}(${columnsString}) VALUES`)
  ->addS(0, valuesString)
  ->build("\n")
}

let fromUpdateQuery = (q: QueryBuilder.Update.tx<_>) => {
  let columns = getNonSkippedColumns(~record=q.patch, ~columns=q.tableColumns)
  let convertedPatch = convertRecordToStringDict(~record=q.patch, ~columns)

  let patchString =
    convertedPatch
    ->Js.Dict.entries
    ->Js.Array2.map(((columnName, value)) => `${columnName} = ${value}`)
    ->Js.Array2.joinWith(", ")

  make()
  ->addS(0, `UPDATE ${q.tableName}`)
  ->addS(2, `SET ${patchString}`)
  ->addSO(2, q.selection->Belt.Option.map(expr => `WHERE ${expressionToSQL(expr)}`))
  ->build("\n")
}

let fromDeleteQuery = (q: QueryBuilder.Delete.t<_>) => {
  make()
  ->addS(0, `DELETE FROM ${q.tableName}`)
  ->addSO(2, q.selection->Belt.Option.map(expr => `WHERE ${expressionToSQL(expr)}`))
  ->build("\n")
}
