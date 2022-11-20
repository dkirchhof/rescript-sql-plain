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
  refs: Js.Dict.t<Any.t>,
  definition: 'definition,
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
  projection: projection<'result>,
}

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
  columns: Item(Utils.columnsToAnyDict(table.columns, Some("t1"))),
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

let select = (q: t<'columns>, getProjection: 'columns => 'result): tx<'result> => {
  let obj = Utils.ItemOrArray.apply(q.columns, getProjection)->Obj.magic

  let counter = ref(0)
  let refs = Js.Dict.empty()

  let rec objToDefinition = obj => {
    obj
    ->Obj.magic
    ->Js.Dict.entries
    ->Js.Array2.map(((key, value)) => {
      let value = Any.make(value)

      switch value {
      | Array(value) => (key, [objToDefinition(value[0])]->Obj.magic)
      | Obj(value) => (key, objToDefinition(value)->Obj.magic)
      | Column(options) => {
          counter.contents = counter.contents + 1

          let alias = `c${counter.contents->Belt.Int.toString}`

          Js.Dict.set(refs, alias, value)

          (key, {"column": alias, "type": options.converter})
      }
      | _ => {
          counter.contents = counter.contents + 1

          let alias = `c${counter.contents->Belt.Int.toString}`

          Js.Dict.set(refs, alias, value)

          (key, {"column": alias, "type": None})
        }
      }
    })
    ->Js.Dict.fromArray
    ->Obj.magic
  }

  let definition = objToDefinition(obj)
  Js.log(definition)

  {from: q.from, joins: q.joins, selection: q.selection, projection: {definition, refs}}
}

let selectAndConvert = (value, converter: 'a => 'b): 'b => {
  let any = value->Obj.magic
  let anyConverter = converter->Obj.magic

  switch any {
    | Any.Column(options) => Any.Column({...options, converter: Some(anyConverter)})->Obj.magic
    | _ => any
  }
}

let mapOne = (q: tx<'result>, row) => {
  NestHydrationJs.make()->NestHydrationJs.nestOne(row, q.projection.definition)
}

let mapMany = (q: tx<'result>, rows) => {
  NestHydrationJs.make()->NestHydrationJs.nestMany(rows, [q.projection.definition])
}
