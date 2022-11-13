open StringBuilder

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
    | Expr.Equal(left, right) => `${left->Obj.magic} = ${right->Obj.magic}`
    }

  let sourceToSQL = (source: SelectQueryBuilder.source) => `${source.name} AS ${source.alias}`

  let joinTypeToSQL = (joinType: SelectQueryBuilder.joinType) =>
    switch joinType {
    | Inner => "INNER JOIN"
    | Left => "LEFT JOIN"
    }

  let joinToSQL = (join: SelectQueryBuilder.join) => {
    let joinTypeString = joinTypeToSQL(join.joinType)
    let tableName = join.source.name
    let tableAlias = join.source.alias
    let exprString = expressionToSQL(join.on)

    `${joinTypeString} ${tableName} AS ${tableAlias} ON ${exprString}`
  }
)

let fromCreateTableQuery = (q: CreateTableQueryBuilder.t<_>) => {
  let sb2 =
    make()
    ->addM(
      2,
      q.table.columns
      ->Obj.magic
      ->Js.Dict.entries
      ->Js.Array2.map(((name: string, column: Schema.Column.t)) =>
        `${name} ${(column.dbType :> string)}(${column.size->Belt.Int.toString}) NOT NULL`
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

let fromSelectQuery = (q: SelectQueryBuilder.tx<_>) => {
  let projectionString =
    make()
    ->addM(0, q.projection.columns->Js.Array2.map(column => `${column} AS '${column}'`))
    ->build(", ")

  make()
  ->addS(0, `SELECT ${projectionString}`)
  ->addS(0, `FROM ${sourceToSQL(q.from)}`)
  ->addM(0, q.joins->Js.Array2.map(joinToSQL))
  ->addSO(0, q.selection->Belt.Option.map(expr => `WHERE ${expressionToSQL(expr)}`))
  ->build("\n")
}
