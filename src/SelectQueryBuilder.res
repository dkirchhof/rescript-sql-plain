open Index

external toAnyTable: Table.t<_, _> => Table.t<Any.t, Any.t> = "%identity"

type t<'projectables, 'selectables> = {
  from: Table.t<Any.t, Any.t>,
  joins: array<Table.t<Any.t, Any.t>>,
  projectables: 'projectables,
  selectables: 'selectables,
  selection: option<Expr.t>,
}

type executable<'resultset> = {
  from: Table.t<Any.t, Any.t>,
  joins: array<Table.t<Any.t, Any.t>>,
  selection: option<Expr.t>,
  resultset: 'resultset,
}

let from = (table: Table.t<'columns, _>): t<'columns, 'columns> => {
  from: table->toAnyTable,
  joins: [],
  projectables: table.columns,
  selectables: table.columns,
  selection: None,
}

let innerJoin1 = (qb: t<'p1, 's1>, table: Table.t<'columns, _>): t<('p1, 'columns), ('s1, 'columns)> => {
  ...qb,
  joins: [table->toAnyTable],
  projectables: (qb.projectables, table.columns),
  selectables: (qb.selectables, table.columns),
}

let leftJoin1 = (qb: t<'p1, 's1>, table: Table.t<'columns, _>): t<('p1, option<'columns>), ('s1, 'columns)> => {
  ...qb,
  joins: [table->toAnyTable],
  projectables: (qb.projectables, Some(table.columns)),
  selectables: (qb.selectables, table.columns),
}

/* let leftJoin2 = (qb: t<('p1, 'p2)>, table: Table.t<'columns, _>): t<('p1, 'p2, 'columns)> => { */
/*   let (p1, p2) = qb.projectables */

/*   { */
/*     from: qb.from, */
/*     joins: Js.Array.concat(qb.joins, [table->toAnyTable]), */
/*     projectables: (p1, p2, table.columns), */
/*   } */
/* } */

let where = (qb: t<_, 'selectables>, getSelection) => {
  let selection = getSelection(qb.selectables)

  {...qb, selection: Some(selection)}
}

let select = (qb: t<'projectables, _>, getProjection): executable<_> => {
  let resultset = getProjection(qb.projectables)

  {from: qb.from, joins: qb.joins, selection: qb.selection, resultset}
}

/* let select2 = (qb: t2<'sources>, getColumns) => { */
/* let columns = getColumns(qb.projectables) */

/* qb */
/* } */

/* let toSQL = (qb: t<'columns, _>) => { */
/* open! StringBuilder */

/* make() */
/* ->addS( */
/* 0, */
/* `SELECT ${qb.columns */
/* ->Obj.magic */
/* ->Js.Dict.values */
/* ->Belt.Array.joinWith(",", (column: Column.t) => column.name)}`, */
/* ) */
/* /1* ->addS(0, `FROM ${qb.from.name}`) *1/ */
/* ->build */
/* } */
