open Index

module Source = {
  type t = {
    name: string,
    alias: string,
  }

  let toSQL = source => `${source.name} AS ${source.alias}`
}

module Join = {
  type joinType = Inner | Left

  type t = {
    source: Source.t,
    joinType: joinType,
    on: Expr.t,
  }

  let joinTypeToString = joinType =>
    switch joinType {
    | Inner => "INNER JOIN"
    | Left => "LEFT JOIN"
    }

  let toSQL = join => {
    let joinTypeString = joinTypeToString(join.joinType)
    let tableName = join.source.name
    let tableAlias = join.source.alias
    let exprString = Expr.toSQL(join.on)

    `${joinTypeString} ${tableName} AS ${tableAlias} ON ${exprString}`
  }
}

type projection<'definition> = {
  columns: array<string>,
  definition: 'definition,
}

type t<'columns> = {
  from: Source.t,
  joins: array<Join.t>,
  columns: Utils.ItemOrArray.t<Js.Dict.t<string>>,
  selection: option<Expr.t>,
}

type executable<'result> = {
  from: Source.t,
  joins: array<Join.t>,
  selection: option<Expr.t>,
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

  let join = (qb, table: Table.t<_>, joinType, getCondition, alias) => {
    let newColumns = Utils.ItemOrArray.concat(qb.columns, [mapColumns(table.columns, alias)])

    let join: Join.t = {
      source: {name: table.name, alias},
      joinType,
      on: Utils.ItemOrArray.apply(newColumns, getCondition),
    }

    let newJoins = Js.Array2.concat(qb.joins, [join])

    {
      ...qb,
      joins: newJoins,
      columns: newColumns,
    }
  }
)

let from = (table: Table.t<'columns, _>): t<'columns> => {
  from: {name: table.name, alias: "a"},
  joins: [],
  columns: Item(mapColumns(table.columns, "a")),
  selection: None,
}

let join1 = (
  qb: t<'c1>,
  table: Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'columns)) => Expr.t,
): t<('c1, 'columns)> => {
  join(qb, table, joinType, getCondition, "b")
}

let join2 = (
  qb: t<('c1, 'c2)>,
  table: Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'c2, 'columns)) => Expr.t,
): t<('c1, 'c2, 'columns)> => {
  join(qb, table, joinType, getCondition, "c")
}

let where = (qb: t<'columns>, getSelection: 'columns => Expr.t): t<'columns> => {
  let selection = Utils.ItemOrArray.apply(qb.columns, getSelection)

  {...qb, selection: Some(selection)}
}

let select = (qb: t<'columns>, getProjection: 'columns => 'result) => {
  let definition = Utils.ItemOrArray.apply(qb.columns, getProjection)
  let columns = Utils.getStringValuesRec(definition)

  {from: qb.from, joins: qb.joins, selection: qb.selection, projection: {definition, columns}}
}

let toSQL = executable => {
  open StringBuilder

  let projectionString =
    make()
    ->addM(0, executable.projection.columns->Js.Array2.map(column => `${column} AS '${column}'`))
    ->build(", ")

  make()
  ->addS(0, `SELECT ${projectionString}`)
  ->addS(0, `FROM ${executable.from->Source.toSQL}`)
  ->addM(0, executable.joins->Js.Array2.map(Join.toSQL))
  ->addSO(0, executable.selection->Belt.Option.map(expr => `WHERE ${Expr.toSQL(expr)}`))
  ->build("\n")
}

let mapOne = (executable: executable<'result>, rows) => {
  NestHydrationJs.make()->NestHydrationJs.nestOne(rows, executable.projection.definition)
}

let mapMany = (executable: executable<'result>, rows) => {
  NestHydrationJs.make()->NestHydrationJs.nestMany(rows, [executable.projection.definition])
}
