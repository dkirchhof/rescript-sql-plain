open Index

%%private(
  let fkStrategyToString = s =>
    switch s {
    | Constraint.CASCADE => "CASCADE"
    | Constraint.NO_ACTION => "NO ACTION"
    | Constraint.RESTRICT => "RESTRICT"
    | Constraint.SET_DEFAULT => "SET DEFAULT"
    | Constraint.SET_NULL => "SET NULL"
    }
)

let toSQL = (table: Index.Table.t<_>) => {
  open! StringBuilder

  let sb2 =
    make()
    ->addM(
      2,
      table.columns
      ->Obj.magic
      ->Js.Dict.entries
      ->Js.Array2.map(((name: string, column: Column.t)) =>
        `${name} ${(column.dbType :> string)}(${column.size->Belt.Int.toString}) NOT NULL`
      ),
    )
    ->addM(
      2,
      table.constraints
      ->Obj.magic
      ->Js.Dict.entries
      ->Js.Array2.map(((name, cnstraint: Constraint.t)) => {
        switch cnstraint {
        | Constraint.PrimaryKey(columns) =>
          `CONSTRAINT ${name} PRIMARY KEY(${columns->Belt.Array.joinWith(",", column =>
              column.name
            )})`
        | Constraint.ForeignKey(ownColumn, foreignColumn, onUpdate, onDelete) =>
          `CONSTRAINT ${name} FOREIGN KEY(${ownColumn.name}) REFERENCES ${foreignColumn.table}(${foreignColumn.name}) ON UPDATE ${fkStrategyToString(
              onUpdate,
            )} ON DELETE ${fkStrategyToString(onDelete)}`
        }
      }),
    )

  make()
  ->addS(0, `CREATE TABLE ${table.name} (`)
  ->addS(0, sb2->buildWithComma)
  ->addS(0, `)`)
  ->build
}
