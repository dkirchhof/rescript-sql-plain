type rec t<'a> =
  | And(array<t<'a>>)
  | Or(array<t<'a>>)
  | Equal('a, 'a)
  | NotEqual('a, 'a)
  | GreaterThan('a, 'a)
  | GreaterThanEqual('a, 'a)
  | LessThan('a, 'a)
  | LessThanEqual('a, 'a)
  | Between('a, 'a, 'a)
  | NotBetween('a, 'a, 'a)
  | In('a, array<'a>)
  | NotIn('a, array<'a>)

let and_ = expressions => And(expressions)
let or = expressions => Or(expressions)

let equal = (column: 't, right:'t) => Equal(
  column,
  right,
)

/* let notEqual = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => NotEqual( */
/*   column, */
/*   right, */
/* ) */

/* let greaterThan = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => GreaterThan( */
/*   column->Schema.Column.toUnknownColumn, */
/*   right->Node.toUnknown, */
/* ) */

/* let greaterThanEqual = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => GreaterThanEqual( */
/*   column->Schema.Column.toUnknownColumn, */
/*   right->Node.toUnknown, */
/* ) */

/* let lessThan = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => LessThan( */
/*   column->Schema.Column.toUnknownColumn, */
/*   right->Node.toUnknown, */
/* ) */

/* let lessThanEqual = (column: Schema.Column.t<'t, _>, right: Node.t<'t, _>) => LessThanEqual( */
/*   column->Schema.Column.toUnknownColumn, */
/*   right->Node.toUnknown, */
/* ) */

/* /1* let \"==" = equal *1/ */
/* /1* let \"!=" = notEqual *1/ */

/* let between = (column: Schema.Column.t<'t, _>, min: Node.t<'t, _>, max: Node.t<'t, _>) => Between( */
/*   column->Schema.Column.toUnknownColumn, */
/*   min->Node.toUnknown, */
/*   max->Node.toUnknown, */
/* ) */

/* let notBetween = ( */
/*   column: Schema.Column.t<'t, _>, */
/*   min: Node.t<'t, _>, */
/*   max: Node.t<'t, _>, */
/* ) => NotBetween(column->Schema.Column.toUnknownColumn, min->Node.toUnknown, max->Node.toUnknown) */

/* let in_ = (column: Schema.Column.t<'t, _>, values: array<Node.t<'t, _>>) => In( */
/*   column->Schema.Column.toUnknownColumn, */
/*   values->Node.toUnknownArray, */
/* ) */

/* let notIn = (column: Schema.Column.t<'t, _>, values: array<Node.t<'t, _>>) => NotIn( */
/*   column->Schema.Column.toUnknownColumn, */
/*   values->Node.toUnknownArray, */
/* ) */
