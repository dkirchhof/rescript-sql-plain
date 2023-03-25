type source = {
  name: string,
  alias: string,
}

type joinType = Inner | Left
type direction = Asc | Desc

type join = {
  source: source,
  joinType: joinType,
  on: (Schema.Column.unknownColumn, Schema.Column.unknownColumn),
}

type order = {
  column: Schema.Column.unknownColumn,
  direction: direction,
}

type t<'columns> = {
  from: source,
  joins: array<join>,
  columns: Utils.ItemOrArray.t<Schema.Column.unknownColumn>,
  selection: option<QueryBuilder_Expr.t>,
  having: option<QueryBuilder_Expr.t>,
  orderBy: option<array<order>>,
  groupBy: option<array<Schema.Column.unknownColumn>>,
  limit: option<int>,
  offset: option<int>,
}

type tx<'result> = {
  from: source,
  joins: array<join>,
  selection: option<QueryBuilder_Expr.t>,
  having: option<QueryBuilder_Expr.t>,
  orderBy: option<array<order>>,
  groupBy: option<array<Schema.Column.unknownColumn>>,
  limit: option<int>,
  offset: option<int>,
  projection: 'result,
}

%%private(
  let join = (q, table: Schema.Table.t<_>, joinType, getCondition, alias) => {
    let newColumns = Utils.ItemOrArray.concat(
      q.columns,
      [
        Schema.Column.Record.mapValues(table.columns, column => {
          ...column,
          table: alias,
        })->Obj.magic,
      ],
    )

    let join: join = {
      source: {name: table.name, alias},
      joinType,
      on: Utils.ItemOrArray.apply(newColumns, getCondition->Obj.magic),
    }

    let newJoins = Js.Array2.concat(q.joins, [join])

    {
      ...q,
      joins: newJoins,
      columns: newColumns,
    }
  }

  let aggregate = (column, aggregation) => {
    open Schema.Column

    {...column, aggregation}
  }
)

let from = (table: Schema.Table.t<'columns, _>): t<'columns> => {
  from: {name: table.name, alias: "t0"},
  joins: [],
  columns: Schema.Column.Record.mapValues(table.columns, column => {...column, table: "t0"})
  ->Obj.magic
  ->Item,
  selection: None,
  having: None,
  orderBy: None,
  groupBy: None,
  limit: None,
  offset: None,
}

let innerJoin1 = (
  q: t<'c1>,
  table: Schema.Table.t<'columns, _>,
  getCondition: (('c1, 'columns)) => (Schema.Column.t<'t, _>, Schema.Column.t<'t, _>),
): t<('c1, 'columns)> => {
  join(q, table, Inner, getCondition, "t1")
}

let leftJoin1 = (
  q: t<'c1>,
  table: Schema.Table.t<'columns, _>,
  getCondition: (('c1, 'columns)) => (Schema.Column.t<'t, _>, Schema.Column.t<'t, _>),
): t<('c1, option<'columns>)> => {
  join(q, table, Left, getCondition, "t1")
}

let innerJoin2 = (
  q: t<('c1, 'c2)>,
  table: Schema.Table.t<'columns, _>,
  getCondition: (('c1, 'c2, 'columns)) => (Schema.Column.t<'t, _>, Schema.Column.t<'t, _>),
): t<('c1, 'c2, 'columns)> => {
  join(q, table, Inner, getCondition, "t2")
}

let leftJoin2 = (
  q: t<('c1, 'c2)>,
  table: Schema.Table.t<'columns, _>,
  getCondition: (('c1, 'c2, 'columns)) => (Schema.Column.t<'t, _>, Schema.Column.t<'t, _>),
): t<('c1, 'c2, option<'columns>)> => {
  join(q, table, Left, getCondition, "t2")
}

let innerJoin3 = (
  q: t<('c1, 'c2, 'c3)>,
  table: Schema.Table.t<'columns, _>,
  getCondition: (('c1, 'c2, 'c3, 'columns)) => (Schema.Column.t<'t, _>, Schema.Column.t<'t, _>),
): t<('c1, 'c2, 'c3, 'columns)> => {
  join(q, table, Inner, getCondition, "t3")
}

let leftJoin3 = (
  q: t<('c1, 'c2, 'c3)>,
  table: Schema.Table.t<'columns, _>,
  getCondition: (('c1, 'c2, 'c3, 'columns)) => (Schema.Column.t<'t, _>, Schema.Column.t<'t, _>),
): t<('c1, 'c2, 'c3, option<'columns>)> => {
  join(q, table, Left, getCondition, "t3")
}

let where = (q: t<'columns>, getSelection: 'columns => QueryBuilder_Expr.t): t<'columns> => {
  let selection = Utils.ItemOrArray.apply(q.columns, getSelection)

  {...q, selection: Some(selection)}
}

let having = (q: t<'columns>, getHaving: 'columns => QueryBuilder_Expr.t): t<'columns> => {
  let having = Utils.ItemOrArray.apply(q.columns, getHaving)

  {...q, having: Some(having)}
}

let addOrderBy = (q: t<'columns>, getColumn: 'columns => Schema.Column.t<_>, direction): t<
  'columns,
> => {
  let columnAndDirection = {
    column: Utils.ItemOrArray.apply(q.columns, getColumn)->Schema.Column.toUnknownColumn,
    direction,
  }

  let orderBy = switch q.orderBy {
  | Some(old) => Js.Array2.concat(old, [columnAndDirection])
  | None => [columnAndDirection]
  }

  {...q, orderBy: Some(orderBy)}
}

let addGroupBy = (q: t<'columns>, getColumn: 'columns => Schema.Column.t<_>): t<'columns> => {
  let column = Utils.ItemOrArray.apply(q.columns, getColumn)->Schema.Column.toUnknownColumn

  let groupBy = switch q.groupBy {
  | Some(old) => Js.Array2.concat(old, [column])
  | None => [column]
  }

  {...q, groupBy: Some(groupBy)}
}

let limit = (q: t<'columns>, limit): t<'columns> => {
  {...q, limit: Some(limit)}
}

let offset = (q: t<'columns>, offset): t<'columns> => {
  {...q, offset: Some(offset)}
}

let select = (q: t<'columns>, getProjection: 'columns => 'result): tx<'result> => {
  let projection = Utils.ItemOrArray.apply(q.columns, getProjection)

  {
    from: q.from,
    joins: q.joins,
    selection: q.selection,
    having: q.having,
    orderBy: q.orderBy,
    groupBy: q.groupBy,
    limit: q.limit,
    offset: q.offset,
    projection,
  }
}

let column = QueryBuilder_Select_Nest.column
let optionalColumn = QueryBuilder_Select_Nest.optionalColumn
let array = QueryBuilder_Select_Nest.array
let optionalArray = QueryBuilder_Select_Nest.optionalArray
let group = QueryBuilder_Select_Nest.group
let optionalGroup = QueryBuilder_Select_Nest.optionalGroup

module Agg = {
  let count = (node): int => aggregate(node, Some(Count))->Schema.Column.toIntColumn->column
  let sum = (node): float => aggregate(node, Some(Sum))->Schema.Column.toFloatColumn->column
  let avg = (node): float => aggregate(node, Some(Avg))->Schema.Column.toFloatColumn->column
  let min = node => aggregate(node, Some(Min))->column
  let max = node => aggregate(node, Some(Max))->column
}
