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

type projectionRef = {
  ref: QueryBuilder_Ref.t,
  alias: string,
}

type projection<'definition> = {
  refs: Js.Dict.t<QueryBuilder_Ref.t>,
  definition: 'definition,
}

type t<'columns> = {
  from: source,
  joins: array<join>,
  columns: Utils.ItemOrArray.t<Js.Dict.t<QueryBuilder_Ref.t>>,
  selection: option<QueryBuilder_Expr.t>,
}

type tx<'result> = {
  from: source,
  joins: array<join>,
  selection: option<QueryBuilder_Expr.t>,
  projection: projection<'result>,
}

%%private(
  let join = (q, table: Schema.Table.t<_>, joinType, getCondition, alias) => {
    let newColumns = Utils.ItemOrArray.concat(
      q.columns,
      [Utils.columnsToRefsDict(table.columns, Some(alias))],
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
  columns: Item(Utils.columnsToRefsDict(table.columns, Some("t1"))),
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

let where = (q: t<'columns>, getSelection: 'columns => QueryBuilder_Expr.t): t<'columns> => {
  let selection = Utils.ItemOrArray.apply(q.columns, getSelection)

  {...q, selection: Some(selection)}
}

let select = (q: t<'columns>, getProjection: 'columns => 'result) => {
  let obj = Utils.ItemOrArray.apply(q.columns, getProjection)

  let counter = ref(0)
  let refs = Js.Dict.empty()

  let rec objToDefinition = obj => {
    obj
    ->Obj.magic
    ->Js.Dict.entries
    ->Js.Array2.map(((key, value)) => {
      if Js.Array2.isArray(value) {
        (key, [objToDefinition(value[0]->Obj.magic)]->Obj.magic)
      } else if Js.Types.test(value, Js.Types.Object) && !QueryBuilder_Ref.isRef(value) {
        (key, objToDefinition(value->Obj.magic)->Obj.magic)
      } else {
        counter.contents = counter.contents + 1

        let alias = `c${counter.contents->Belt.Int.toString}`

        Js.Dict.set(refs, alias, QueryBuilder_Ref.make(value))

        (key, alias)
      }
    })
    ->Js.Dict.fromArray
  }

  let definition = objToDefinition(obj)

  Js.log(definition)
  Js.log(refs)

  {from: q.from, joins: q.joins, selection: q.selection, projection: {definition, refs}}
}

let mapOne = (q: tx<'result>, row) => {
  NestHydrationJs.make()->NestHydrationJs.nestOne(row, q.projection.definition)
}

let mapMany = (q: tx<'result>, rows) => {
  NestHydrationJs.make()->NestHydrationJs.nestMany(rows, [q.projection.definition])
}
