module FKStrategy = {
  type t = Restrict | Cascade | SetNull | NoAction | SetDefault
}

type t =
  | PrimaryKey(array<Node.unknownNode>)
  | ForeignKey(Node.unknownNode, Node.unknownNode, FKStrategy.t, FKStrategy.t)

let primaryKey = columns => {
  columns->Obj.magic->Utils.ensureArray->PrimaryKey
}

let foreignKey = (~ownColumn: Node.t<'a, _>, ~foreignColumn: Node.t<'a, _>, ~onUpdate, ~onDelete) => {
  ForeignKey(
    ownColumn->Obj.magic,
    foreignColumn->Obj.magic,
    onUpdate,
    onDelete,
  )
}
