type source = {
  name: string,
  alias: string,
}

type joinType = Inner | Left
type direction = Asc | Desc

type join = {
  source: source,
  joinType: joinType,
  on: QueryBuilder_Expr.t,
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
      on: Utils.ItemOrArray.apply(newColumns, getCondition),
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

let join1 = (
  q: t<'c1>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'columns)) => QueryBuilder_Expr.t,
): t<('c1, 'columns)> => {
  join(q, table, joinType, getCondition, "t1")
}

let join2 = (
  q: t<('c1, 'c2)>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'c2, 'columns)) => QueryBuilder_Expr.t,
): t<('c1, 'c2, 'columns)> => {
  join(q, table, joinType, getCondition, "t2")
}

let join3 = (
  q: t<('c1, 'c2, 'c3)>,
  table: Schema.Table.t<'columns, _>,
  joinType,
  getCondition: (('c1, 'c2, 'c3, 'columns)) => QueryBuilder_Expr.t,
): t<('c1, 'c2, 'c3, 'columns)> => {
  join(q, table, joinType, getCondition, "t3")
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

let s = (column: Schema.Column.t<'a, _>): 'a => Node.Column(column)->Obj.magic

module Agg = {
  let count = (node): int => aggregate(node, Some(Count))->s->Obj.magic
  let sum = (node): float => aggregate(node, Some(Sum))->s->Obj.magic
  let avg = (node): float => aggregate(node, Some(Avg))->s->Obj.magic
  let min = node => aggregate(node, Some(Min))->s
  let max = node => aggregate(node, Some(Max))->s
}

let map = (q: tx<'projection>, row): 'projection => {
  row->Utils.mapEntries(((columnName, value)) => {
    let node = q.projection->Node.dictFromRecord->Js.Dict.unsafeGet(columnName)

    let convertedValue = switch node {
    | Node.Column({converter: Some(converter)}) => value->converter.dbToRes
    | _ => value
    }

    (columnName, convertedValue)
  })
}
