type source = {
  name: string,
  alias: string,
}

type joinType = Inner | Left

type join = {
  source: source,
  joinType: joinType,
  on: QueryBuilder_Expr.t,
}

type t<'columns> = {
  from: source,
  joins: array<join>,
  columns: Utils.ItemOrArray.t<Js.Dict.t<Any.t>>,
  selection: option<QueryBuilder_Expr.t>,
}

type tx<'result> = {
  from: source,
  joins: array<join>,
  selection: option<QueryBuilder_Expr.t>,
  projection: 'result,
}

let mapColumns = (columns, f) =>
  columns
  ->Node.dictFromRecord
  ->Js.Dict.entries
  ->Js.Array2.map(((columnName, node)) => {
    let column = Node.getColumnExn(node)
    let mapped = column->f->Node.Column

    (columnName, mapped)
  })
  ->Js.Dict.fromArray
  ->Node.recordFromDict

%%private(
  let join = (q, table: Schema.Table.t<_>, joinType, getCondition, alias) => {
    let newColumns = Utils.ItemOrArray.concat(
      q.columns,
      [Utils.columnsToAnyDict(table.columns, Some(alias))],
    )

    let join: join = {
      source: {name: table.name, alias},
      joinType,
      on: Utils.ItemOrArray.apply(newColumns, getCondition),
    }

    let newJoins = Js.Array2.concat(q.joins, [join])

    {
      ...q,
      joins: newJoins,
      columns: newColumns,
    }
  }
)

let from = (table: Schema.Table.t<'columns, _>): t<'columns> => {
  from: {name: table.name, alias: "t1"},
  joins: [],
  columns: mapColumns(table.columns, column => {...column, table: "t1"})->Item,
  selection: None,
}

let join1 = (
  q: t<'c1>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'columns)) => QueryBuilder_Expr.t,
): t<('c1, 'columns)> => {
  join(q, table, joinType, getCondition, "t2")
}

let join2 = (
  q: t<('c1, 'c2)>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'c2, 'columns)) => QueryBuilder_Expr.t,
): t<('c1, 'c2, 'columns)> => {
  join(q, table, joinType, getCondition, "t3")
}

let join3 = (
  q: t<('c1, 'c2, 'c3)>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'c2, 'c3, 'columns)) => QueryBuilder_Expr.t,
): t<('c1, 'c2, 'c3, 'columns)> => {
  join(q, table, joinType, getCondition, "t4")
}

let where = (q: t<'columns>, getSelection: 'columns => QueryBuilder_Expr.t): t<'columns> => {
  let selection = Utils.ItemOrArray.apply(q.columns, getSelection)

  {...q, selection: Some(selection)}
}

let select = (q: t<'columns>, getProjection: 'columns => 'result): tx<'result> => {
  let projection = Utils.ItemOrArray.apply(q.columns, getProjection)

  {from: q.from, joins: q.joins, selection: q.selection, projection}
}

external s: Node.t<'a, _> => 'a = "%identity"

/* let mapOne = (q: tx<'result>, row) => { */
/* NestHydrationJs.make()->NestHydrationJs.nestOne(row, q.projection.definition) */
/* } */

/* let mapMany = (q: tx<'result>, rows) => { */
/* NestHydrationJs.make()->NestHydrationJs.nestMany(rows, [q.projection.definition]) */
/* } */

let map = (projection: 'projection, row): 'projection => {
  row
  ->Obj.magic
  ->Js.Dict.entries
  ->Js.Array2.map(((columnName, value)) => {
    let node = projection->Node.dictFromRecord->Js.Dict.unsafeGet(columnName)

    let convertedValue = switch node {
    | Column({converter: Some(converter)}) => value->converter.dbToRes
    | _ => value
    }

    (columnName, convertedValue)
  })
  ->Js.Dict.fromArray
  ->Obj.magic
}
