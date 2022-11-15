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

type projection<'definition> = {
  columns: array<string>,
  definition: 'definition,
}

type t<'columns> = {
  from: source,
  joins: array<join>,
  columns: Utils.ItemOrArray.t<Js.Dict.t<string>>,
  selection: option<QueryBuilder_Expr.t>,
}

type tx<'result> = {
  from: source,
  joins: array<join>,
  selection: option<QueryBuilder_Expr.t>,
  projection: projection<'result>,
}

%%private(
  let mapColumns = (columns, alias) => {
    columns
    ->Obj.magic
    ->Js.Dict.keys
    ->Js.Array2.map(column => (column, `${alias}.${column}`))
    ->Js.Dict.fromArray
  }

  let join = (q, table: Schema.Table.t<_>, joinType, getCondition, alias) => {
    let newColumns = Utils.ItemOrArray.concat(q.columns, [mapColumns(table.columns, alias)])

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
  from: {name: table.name, alias: "a"},
  joins: [],
  columns: Item(mapColumns(table.columns, "a")),
  selection: None,
}

let join1 = (
  q: t<'c1>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'columns)) => QueryBuilder_Expr.t,
): t<('c1, 'columns)> => {
  join(q, table, joinType, getCondition, "b")
}

let join2 = (
  q: t<('c1, 'c2)>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'c2, 'columns)) => QueryBuilder_Expr.t,
): t<('c1, 'c2, 'columns)> => {
  join(q, table, joinType, getCondition, "c")
}

let where = (q: t<'columns>, getSelection: 'columns => QueryBuilder_Expr.t): t<'columns> => {
  let selection = Utils.ItemOrArray.apply(q.columns, getSelection)

  {...q, selection: Some(selection)}
}

let select = (q: t<'columns>, getProjection: 'columns => 'result) => {
  let definition = Utils.ItemOrArray.apply(q.columns, getProjection)
  let columns = Utils.getStringValuesRec(definition)

  {from: q.from, joins: q.joins, selection: q.selection, projection: {definition, columns}}
}

let mapOne = (q: tx<'result>, row) => {
  NestHydrationJs.make()->NestHydrationJs.nestOne(row, q.projection.definition)
}

let mapMany = (q: tx<'result>, rows) => {
  NestHydrationJs.make()->NestHydrationJs.nestMany(rows, [q.projection.definition])
}
