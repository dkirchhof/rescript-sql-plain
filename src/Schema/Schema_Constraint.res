module FKStrategy = {
  type t = Restrict | Cascade | SetNull | NoAction | SetDefault
}

type t =
  | PrimaryKey(array<Schema_Column.t<Any.t, Any.t>>)
  | ForeignKey(Schema_Column.t<Any.t, Any.t>, Schema_Column.t<Any.t, Any.t>, FKStrategy.t, FKStrategy.t)

let primaryKey = columns => {
  columns->Obj.magic->Utils.ensureArray->PrimaryKey
}

let foreignKey = (~ownColumn: 'a, ~foreignColumn: 'a, ~onUpdate, ~onDelete) => {
  ForeignKey(
    ownColumn->Obj.magic,
    foreignColumn->Obj.magic,
    onUpdate,
    onDelete,
  )
}
