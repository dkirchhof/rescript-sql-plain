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
