open StringBuilder

let convertIfNecessary2 = (value, targetColumn: Schema_Column.t<_>) => {
  switch targetColumn.converter {
  | Some(converter) => value->converter.resToDB
  | _ => value
  }
}

let convertIfNecessary = (sourceNode, targetColumn: Schema_Column.t<_>) => {
  switch sourceNode {
  | Node.Literal(value) => convertIfNecessary2(value, targetColumn)->Node.Literal
  | _ => sourceNode
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
    | Node.Literal(value) => convertIfNecessary2(value, column)->Utils.stringify
    | _ => Js.Exn.raiseError("not implemented yet")
    }

    (column.name, valueString)
  })
  ->Js.Dict.fromArray
}

let expressionToSQL = expr =>
  switch expr {
  | QueryBuilder.Expr.Equal(left, right) => {
      let column = left->Node.getColumnExn

      let valueString = switch right {
      | Node.Literal(value) => convertIfNecessary2(value, column)->Utils.stringify
      | Node.Column(column) => `${column.table}.${column.name}`
      | _ => Js.Exn.raiseError("not implemented yet")
      }

      `${column.table}.${column.name} = ${valueString}`
    }
  }

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
