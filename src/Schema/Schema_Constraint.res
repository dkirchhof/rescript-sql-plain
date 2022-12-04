module FKStrategy = {
  type t = Restrict | Cascade | SetNull | NoAction | SetDefault
}

type t =
  | PrimaryKey(array<Schema_Column.unknownColumn>)
  | ForeignKey(Schema_Column.unknownColumn, Schema_Column.unknownColumn, FKStrategy.t, FKStrategy.t)

let primaryKey = columns => {
  columns->Obj.magic->Utils.ensureArray->PrimaryKey
}

let foreignKey = (~ownColumn: Schema_Column.t<'a, _>, ~foreignColumn: Schema_Column.t<'a, _>, ~onUpdate, ~onDelete) => {
  ForeignKey(
    ownColumn->Schema_Column.toUnknownColumn,
    foreignColumn->Schema_Column.toUnknownColumn,
    onUpdate,
    onDelete,
  )
}
