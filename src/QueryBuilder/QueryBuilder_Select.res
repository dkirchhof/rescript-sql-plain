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

type t<'columns, 'a> = {
  from: source,
  joins: array<join>,
  columns: Utils.ItemOrArray.t<Schema.Column.unknownColumn>,
  selection: option<QueryBuilder_Expr.t<'a>>,
  having: option<QueryBuilder_Expr.t<'a>>,
  orderBy: option<array<order>>,
  groupBy: option<array<Schema.Column.unknownColumn>>,
  limit: option<int>,
  offset: option<int>,
}

type tx<'result, 'a> = {
  from: source,
  joins: array<join>,
  selection: option<QueryBuilder_Expr.t<'a>>,
  having: option<QueryBuilder_Expr.t<'a>>,
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

let from = (table: Schema.Table.t<'columns, _>): t<'columns, _> => {
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

let join1 = (
  q: t<'c1, _>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'columns)) => (Schema.Column.t<'t, _>, Schema.Column.t<'t, _>),
): t<('c1, 'columns), _> => {
  join(q, table, joinType, getCondition, "t1")
}

let join2 = (
  q: t<('c1, 'c2), _>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'c2, 'columns)) => (Schema.Column.t<'t, _>, Schema.Column.t<'t, _>),
): t<('c1, 'c2, 'columns), _> => {
  join(q, table, joinType, getCondition, "t2")
}

let join3 = (
  q: t<('c1, 'c2, 'c3), _>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'c2, 'c3, 'columns)) => (Schema.Column.t<'t, _>, Schema.Column.t<'t, _>),
): t<('c1, 'c2, 'c3, 'columns), _> => {
  join(q, table, joinType, getCondition, "t3")
}

let where = (q: t<'columns, _>, getSelection: 'columns => QueryBuilder_Expr.t<_>): t<'columns, _> => {
  let selection = Utils.ItemOrArray.apply(q.columns, getSelection)

  {...q, selection: Some(selection)}
}

let having = (q: t<'columns, _>, getHaving: 'columns => QueryBuilder_Expr.t<_>): t<'columns, _> => {
  let having = Utils.ItemOrArray.apply(q.columns, getHaving)

  {...q, having: Some(having)}
}

let addOrderBy = (q: t<'columns, _>, getColumn: 'columns => Schema.Column.t<_>, direction): t<'columns, _,
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

let addGroupBy = (q: t<'columns, _>, getColumn: 'columns => Schema.Column.t<_>): t<'columns, _> => {
  let column = Utils.ItemOrArray.apply(q.columns, getColumn)->Schema.Column.toUnknownColumn

  let groupBy = switch q.groupBy {
  | Some(old) => Js.Array2.concat(old, [column])
  | None => [column]
  }

  {...q, groupBy: Some(groupBy)}
}

let limit = (q: t<'columns, _>, limit): t<'columns, _> => {
  {...q, limit: Some(limit)}
}

let offset = (q: t<'columns, _>, offset): t<'columns, _> => {
  {...q, offset: Some(offset)}
}

let select = (q: t<'columns, _>, getProjection: 'columns => 'result): tx<'result, _> => {
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

let column = (column: Schema.Column.t<'a, _>): 'a => Node.Column(column)->Obj.magic

module Agg = {
  let count = (node): int => aggregate(node, Some(Count))->column->Obj.magic
  let sum = (node): float => aggregate(node, Some(Sum))->column->Obj.magic
  let avg = (node): float => aggregate(node, Some(Avg))->column->Obj.magic
  let min = node => aggregate(node, Some(Min))->column
  let max = node => aggregate(node, Some(Max))->column
}

let map = (q: tx<'projection, _>, row): 'projection => {
  row->Utils.mapEntries(((columnName, value)) => {
    let node = q.projection->Node.dictFromRecord->Js.Dict.unsafeGet(columnName)

    let convertedValue = switch node {
    | Node.Column({converter: Some(converter)}) => value->converter.dbToRes
    | _ => value
    }

    (columnName, convertedValue)
  })
}
