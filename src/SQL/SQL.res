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

      | _ => Js.Exn.raiseError("These values should be columns.")
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

  let convertIfNecessary = (sourceNode, targetNode) => {
    switch sourceNode {
    | Node.Literal(value) => {
        let convertedValue = switch targetNode {
        | Node.Column({converter: Some(converter)}) => converter.resToDB(value)
        | _ => value
        }

        if Js.Types.test(convertedValue, Js.Types.String) {
          `'${convertedValue->Obj.magic->Utils.replaceAll("'", "''")}'`
        } else {
          convertedValue->Obj.magic
        }
      }

    | _ => Js.Exn.raiseError("not implemented")
    }
  }
)

let fromCreateTableQuery = (q: QueryBuilder.CreateTable.t<_>) => {
  let sb2 =
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

let fromInsertIntoQuery = (q: QueryBuilder.Insert.tx<_>) => {
  let columnNames =
    q.values[0]
    ->Node.dictFromRecord
    ->Js.Dict.entries
    ->Js.Array2.filter(((_, value)) => value !== Node.Skip)
    ->Js.Array2.map(fst)

  let columnsString = columnNames->Js.Array2.joinWith(", ")

  let rowStrings = q.values->Js.Array2.map(row => {
    let rowString =
      columnNames
      ->Js.Array2.map(columnName => {
        let column = q.tableColumns->Node.dictFromRecord->Js.Dict.unsafeGet(columnName)

        row->Node.dictFromRecord->Js.Dict.unsafeGet(columnName)->convertIfNecessary(column)
      })
      ->Js.Array2.joinWith(", ")

    `(${rowString})`
  })

  let valuesString = make()->addM(2, rowStrings)->build(",\n")

  make()
  ->addS(0, `INSERT INTO ${q.tableName}(${columnsString}) VALUES`)
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
