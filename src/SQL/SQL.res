open StringBuilder

%%private(
  let anyToSQL = value => {
    switch value {
    | Any.Number(value) => value->Belt.Float.toString
    | Any.String(value) => `'${value->Utils.replaceAll("'", "''")}'`
    | Any.Date(value) => `'${value->Js.Date.toISOString}'`
    | Any.Column(options) =>
      switch options.tableAlias {
      | Some(tableAlias) => `${tableAlias}.${options.columnName}`
      | None => options.columnName
      }
    | Any.Skip | Any.Obj(_) | Any.Array(_) => Js.Exn.raiseError("Value has type Undefined")
    }
  }

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
    | Schema.Constraint.PrimaryKey(columns) => {
        let columnsString = columns->Belt.Array.joinWith(",", column => column.name)

        `CONSTRAINT ${name} PRIMARY KEY(${columnsString})`
      }

    | ForeignKey(ownColumn, foreignColumn, onUpdate, onDelete) => {
        let references = `REFERENCES ${foreignColumn.table}(${foreignColumn.name})`
        let onUpdate = `ON UPDATE ${fkStrategyToSQL(onUpdate)}`
        let onDelete = `ON DELETE ${fkStrategyToSQL(onDelete)}`

        `CONSTRAINT ${name} FOREIGN KEY(${ownColumn.name}) ${references} ${onUpdate} ${onDelete}`
      }
    }

  let expressionToSQL = expr =>
    switch expr {
    | QueryBuilder.Expr.Equal(left, right) => `${left->anyToSQL} = ${right->anyToSQL}`
    }

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
  let sb2 =
    make()
    ->addM(
      2,
      q.table.columns
      ->Obj.magic
      ->Js.Dict.entries
      ->Js.Array2.map(((name: string, column: Schema.Column.t<Any.t, Any.t>)) =>
        switch column.size {
        | Some(size) => `${name} ${(column.dbType :> string)}(${size->Belt.Int.toString}) NOT NULL`
        | None => `${name} ${(column.dbType :> string)} NOT NULL`
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

  make()
  ->addS(0, `CREATE TABLE ${q.table.name} (`)
  ->addS(0, sb2->build(",\n"))
  ->addS(0, `)`)
  ->build("\n")
}

let fromSelectQuery = (q: QueryBuilder.Select.tx<_>) => {
  let projectionString =
    make()
    ->addM(
      0,
      q.projection.refs
      ->Js.Dict.entries
      ->Js.Array2.map(((alias, value)) => `${value->anyToSQL} AS '${alias}'`),
    )
    ->build(", ")

  make()
  ->addS(0, `SELECT ${projectionString}`)
  ->addS(0, `FROM ${sourceToSQL(q.from)}`)
  ->addM(0, q.joins->Js.Array2.map(joinToSQL))
  ->addSO(0, q.selection->Belt.Option.map(expr => `WHERE ${expressionToSQL(expr)}`))
  ->build("\n")
}

%%private(
  let rowToValues = (row, column) => row->Obj.magic->Js.Dict.unsafeGet(column)->anyToSQL

  let rowToValuesString = (columns, row) =>
    `(${columns->Js.Array2.map(rowToValues(row))->Js.Array2.joinWith(", ")})`
)

let fromInsertIntoQuery = (q: QueryBuilder.Insert.tx<_>) => {
  let columns =
    q.values[0]
    ->Obj.magic
    ->Js.Dict.entries
    ->Js.Array2.filter(((_, value)) => value !== Any.Skip)
    ->Js.Array2.map(fst)

  let columnsString = columns->Js.Array2.joinWith(", ")

  let valuesString =
    make()->addM(2, q.values->Js.Array2.map(rowToValuesString(columns)))->build(",\n")

  make()
  ->addS(0, `INSERT INTO ${q.table} (${columnsString})`)
  ->addS(0, `VALUES`)
  ->addS(0, valuesString)
  ->build("\n")
}

let fromUpdateQuery = (q: QueryBuilder.Update.tx<_>) => {
  let patchString =
    q.patch
    ->Obj.magic
    ->Js.Dict.entries
    ->Js.Array2.filter(((_, value)) => value !== Any.Skip)
    ->Js.Array2.map(((column, value)) => `${column} = ${anyToSQL(value)}`)
    ->Js.Array2.joinWith(", ")

  make()
  ->addS(0, `UPDATE ${q.table}`)
  ->addS(2, `SET ${patchString}`)
  ->addSO(2, q.selection->Belt.Option.map(expr => `WHERE ${expressionToSQL(expr)}`))
  ->build("\n")
}

let fromDeleteQuery = (q: QueryBuilder.Delete.t<_>) => {
  make()
  ->addS(0, `DELETE FROM ${q.table}`)
  ->addSO(2, q.selection->Belt.Option.map(expr => `WHERE ${expressionToSQL(expr)}`))
  ->build("\n")
}
