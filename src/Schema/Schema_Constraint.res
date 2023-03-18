module FKStrategy = {
  type t = Restrict | Cascade | SetNull | NoAction | SetDefault
}

type t<'a> =
  | PrimaryKey(array<Schema_Column.unknownColumn>)
  | ForeignKey('a, 'a, FKStrategy.t, FKStrategy.t)

let primaryKey = columns => {
  columns->Obj.magic->Utils.ensureArray->PrimaryKey
}

let foreignKey = (~ownColumn: 'a, ~foreignColumn: 'a, ~onUpdate, ~onDelete) => {
  ForeignKey(
    ownColumn,
    foreignColumn,
    onUpdate,
    onDelete,
  )
}
