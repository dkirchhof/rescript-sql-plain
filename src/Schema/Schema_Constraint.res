module FKStrategy = {
  type t = Restrict | Cascade | SetNull | NoAction | SetDefault
}

type t =
  | PrimaryKey(array<ColumnOrLiteral.t<unknown, unknown>>)
  | ForeignKey(ColumnOrLiteral.t<unknown, unknown>, ColumnOrLiteral.t<unknown, unknown>, FKStrategy.t, FKStrategy.t)

let primaryKey = columns => {
  columns->Obj.magic->Utils.ensureArray->PrimaryKey
}

let foreignKey = (~ownColumn: ColumnOrLiteral.t<'a, _>, ~foreignColumn: ColumnOrLiteral.t<'a, _>, ~onUpdate, ~onDelete) => {
  ForeignKey(
    ownColumn->Obj.magic,
    foreignColumn->Obj.magic,
    onUpdate,
    onDelete,
  )
}
