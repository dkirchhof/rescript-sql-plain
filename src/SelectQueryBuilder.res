open Index

external toAnyTable: Table.t<_, _> => Table.t<Any.t, Any.t> = "%identity"

type projection<'definition> = {
  columns: array<string>,
  definition: 'definition,
}

let makeProjection: ('row => 'result) => projection<'result> = %raw(`
  function(cb) {
    const columns = new Set();

    const proxy = new Proxy({}, {
      get(_, index) {
        return new Proxy({}, {
          get(_, prop) {
            const column = index + "_" + prop;

            columns.add(column);

            return column;
          },
        });
      },
    });

    return {
      columns,
      definition: cb(proxy),
    };
  }
`)

type joinType = Inner | Left

type join = {
  table: Table.t<Any.t, Any.t>,
  joinType: joinType,
  on: Expr.t,
}

type t<'columns> = {
  from: Table.t<Any.t, Any.t>,
  joins: array<join>,
  columns: 'columns,
  selection: option<Expr.t>,
}

type executable<'result> = {
  from: Table.t<Any.t, Any.t>,
  joins: array<join>,
  selection: option<Expr.t>,
  projection: projection<'result>,
}

let from = (table: Table.t<'columns, _>): t<'columns> => {
  from: table->toAnyTable,
  joins: [],
  columns: table.columns,
  selection: None,
}

let join1 = (qb: t<'c1>, table: Table.t<'columns, _>, joinType, getCondition): t<(
  'c1,
  'columns,
)> => {
  let c1 = qb.columns

  let columns = (c1, table.columns)

  let join = {
    table: table->toAnyTable,
    joinType,
    on: getCondition(columns),
  }

  {
    ...qb,
    joins: Js.Array.concat(qb.joins, [join]),
    columns,
  }
}

let join2 = (qb: t<('c1, 'c2)>, table: Table.t<'columns, _>, joinType, getCondition): t<(
  'c1,
  'c2,
  'columns,
)> => {
  let (c1, c2) = qb.columns

  let columns = (c1, c2, table.columns)

  let join = {
    table: table->toAnyTable,
    joinType,
    on: getCondition(columns),
  }

  {
    ...qb,
    joins: Js.Array.concat(qb.joins, [join]),
    columns,
  }
}

let where = (qb, getSelection) => {
  let selection = getSelection(qb.columns)

  {...qb, selection: Some(selection)}
}

let select = (qb: t<'columns>, getProjection: 'columns => 'result) => {
  let projection = makeProjection(getProjection)

  {from: qb.from, joins: qb.joins, selection: qb.selection, projection}
}

let mapResult = (executable: executable<'result>, rows) => {
  NestHydrationJs.make()->NestHydrationJs.nestMany(rows, [executable.projection.definition])
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
