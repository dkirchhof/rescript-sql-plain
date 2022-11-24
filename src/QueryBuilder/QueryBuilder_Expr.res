type rec t =
  | And(array<t>)
  | Or(array<t>)
  | Equal(Node.unknownNode, Node.unknownNode)
  | NotEqual(Node.unknownNode, Node.unknownNode)
  | GreaterThan(Node.unknownNode, Node.unknownNode)
  | GreaterThanEqual(Node.unknownNode, Node.unknownNode)
  | LessThan(Node.unknownNode, Node.unknownNode)
  | LessThanEqual(Node.unknownNode, Node.unknownNode)
  | Between(Node.unknownNode, Node.unknownNode, Node.unknownNode)
  | NotBetween(Node.unknownNode, Node.unknownNode, Node.unknownNode)
  | In(Node.unknownNode, array<Node.unknownNode>)
  | NotIn(Node.unknownNode, array<Node.unknownNode>)

let and_ = expressions => And(expressions)
let or = expressions => Or(expressions)

let equal = (left: 't, right: 't) => Equal(left->Node.toUnknown, right->Node.toUnknown)
let notEqual = (left: 't, right: 't) => NotEqual(left->Node.toUnknown, right->Node.toUnknown)

let greaterThan = (left: 't, right: 't) => GreaterThan(left->Node.toUnknown, right->Node.toUnknown)

let greaterThanEqual = (left: 't, right: 't) => GreaterThanEqual(
  left->Node.toUnknown,
  right->Node.toUnknown,
)

let lessThan = (left: 't, right: 't) => LessThan(left->Node.toUnknown, right->Node.toUnknown)

let lessThanEqual = (left: 't, right: 't) => LessThanEqual(
  left->Node.toUnknown,
  right->Node.toUnknown,
)

/* let \"==" = equal */
/* let \"!=" = notEqual */

let between = (column, min, max) => Between(
  column->Node.toUnknown,
  min->Node.toUnknown,
  max->Node.toUnknown,
)

let notBetween = (column, min, max) => NotBetween(
  column->Node.toUnknown,
  min->Node.toUnknown,
  max->Node.toUnknown,
)

let in_ = (column, values) => In(column->Node.toUnknown, values->Node.toUnknownArray)
let notIn = (column, values) => NotIn(column->Node.toUnknown, values->Node.toUnknownArray)
