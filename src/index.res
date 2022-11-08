module Column = {
  type t = {
    table: string,
    name: string,
    dbType: [#VARCHAR | #INTEGER],
    size: int,
  }

  type options = {size: int}

  let varchar = (options): string => {
    {table: "", name: "", dbType: #VARCHAR, size: options.size}->Obj.magic
  }

  let integer = (options): int => {
    {table: "", name: "", dbType: #INTEGER, size: options.size}->Obj.magic
  }
}

module Constraint = {
  type fkStrategy = RESTRICT | CASCADE | SET_NULL | NO_ACTION | SET_DEFAULT
  type t = PrimaryKey(array<Column.t>) | ForeignKey(Column.t, Column.t, fkStrategy, fkStrategy)

  let primaryKey = columns => {
    columns->Obj.magic->Utils.ensureArray->PrimaryKey
  }

  let foreignKey = (~ownColumn: 'a, ~foreignColumn: 'a, ~onUpdate, ~onDelete) => {
    ForeignKey(ownColumn->Obj.magic, foreignColumn->Obj.magic, onUpdate, onDelete)
  }
}

module Table = {
  type t<'columns, 'constraints> = {
    name: string,
    columns: 'columns,
    constraints: 'constraints,
  }

  let make = (name, columns: 'a, makeConstraints: 'a => 'b) => {
    let columns: 'a =
      columns
      ->Obj.magic
      ->Js.Dict.entries
      ->Js.Array2.map(((columnName, column: Column.t)) => (
        columnName,
        {...column, table: name, name: columnName},
      ))
      ->Js.Dict.fromArray
      ->Obj.magic

    {name, columns, constraints: makeConstraints(columns)}
  }
}
