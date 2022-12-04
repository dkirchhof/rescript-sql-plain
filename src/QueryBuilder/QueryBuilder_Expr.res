type rec t =
  | And(array<t>)
  | Or(array<t>)
  | Equal(Schema.Column.unknownColumn, Node.unknownNode)
  | NotEqual(Schema.Column.unknownColumn, Node.unknownNode)
  | GreaterThan(Schema.Column.unknownColumn, Node.unknownNode)
  | GreaterThanEqual(Schema.Column.unknownColumn, Node.unknownNode)
  | LessThan(Schema.Column.unknownColumn, Node.unknownNode)
  | LessThanEqual(Schema.Column.unknownColumn, Node.unknownNode)
  | Between(Schema.Column.unknownColumn, Node.unknownNode, Node.unknownNode)
  | NotBetween(Schema.Column.unknownColumn, Node.unknownNode, Node.unknownNode)
  | In(Schema.Column.unknownColumn, array<Node.unknownNode>)
  | NotIn(Schema.Column.unknownColumn, array<Node.unknownNode>)

let and_ = expressions => And(expressions)
let or = expressions => Or(expressions)

let equal = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => Equal(
  column->Schema.Column.toUnknownColumn,
  right->Node.toUnknown,
)

let notEqual = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => NotEqual(
  column->Schema.Column.toUnknownColumn,
  right->Node.toUnknown,
)

let greaterThan = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => GreaterThan(
  column->Schema.Column.toUnknownColumn,
  right->Node.toUnknown,
)

let greaterThanEqual = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => GreaterThanEqual(
  column->Schema.Column.toUnknownColumn,
  right->Node.toUnknown,
)

let lessThan = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => LessThan(
  column->Schema.Column.toUnknownColumn,
  right->Node.toUnknown,
)

let lessThanEqual = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => LessThanEqual(
  column->Schema.Column.toUnknownColumn,
  right->Node.toUnknown,
)

/* let \"==" = equal */
/* let \"!=" = notEqual */

let between = (column: Schema.Column.t<'t, _>, min: Node.t<'t, _>, max: Node.t<'t, _>) => Between(
  column->Schema.Column.toUnknownColumn,
  min->Node.toUnknown,
  max->Node.toUnknown,
)

let notBetween = (
  column: Schema.Column.t<'t, _>,
  min: Node.t<'t, _>,
  max: Node.t<'t, _>,
) => NotBetween(column->Schema.Column.toUnknownColumn, min->Node.toUnknown, max->Node.toUnknown)

let in_ = (column: Schema.Column.t<'t, _>, values: array<Node.t<'t, _>>) => In(
  column->Schema.Column.toUnknownColumn,
  values->Node.toUnknownArray,
)

let notIn = (column: Schema.Column.t<'t, _>, values: array<Node.t<'t, _>>) => NotIn(
  column->Schema.Column.toUnknownColumn,
  values->Node.toUnknownArray,
)
