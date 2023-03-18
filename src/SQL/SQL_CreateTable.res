open StringBuilder

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
      let columnsString = nodes->Belt.Array.joinWith(", ", column => column.name)

      `CONSTRAINT ${name} PRIMARY KEY(${columnsString})`
    }

  | ForeignKey(ownColumn, foreignColumn, onUpdate, onDelete) => {
      let ownColumn = Schema.Column.fromAny(ownColumn)
      let foreignColumn = Schema.Column.fromAny(foreignColumn)

      let references = `REFERENCES ${foreignColumn.table}(${foreignColumn.name})`
      let onUpdate = `ON UPDATE ${fkStrategyToSQL(onUpdate)}`
      let onDelete = `ON DELETE ${fkStrategyToSQL(onDelete)}`

      `CONSTRAINT ${name} FOREIGN KEY(${ownColumn.name}) ${references} ${onUpdate} ${onDelete}`
    }
  }

let fromCreateTableQuery = (q: QueryBuilder.CreateTable.t<_>) => {
  let innerString =
    make()
    ->addM(
      2,
      q.table.columns
      ->Schema.Column.dictFromRecord
      ->Js.Dict.entries
      ->Js.Array2.map(((name, column)) => {
        let sizeString = switch column.size {
        | Some(size) => `(${size->Belt.Int.toString})`
        | None => ""
        }

        let notNullString = column.nullable ? "" : " NOT NULL"

        `${name} ${(column.dbType :> string)}${sizeString}${notNullString}`
      }),
    )
    ->addM(
      2,
      q.table.constraints
      ->Obj.magic
      ->Js.Dict.entries
      ->Js.Array2.map(((name, cnstraint: Schema.Constraint.t<_>)) => constraintToSQL(name, cnstraint)),
    )
    ->build(",\n")

  make()->addS(0, `CREATE TABLE ${q.table.name} (`)->addS(0, innerString)->addS(0, `)`)->build("\n")
}
