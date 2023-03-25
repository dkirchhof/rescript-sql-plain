type rec definitionNode =
  | ValueDefinition(unknown)
  | ColumnDefinition(Schema.Column.unknownColumn)
  | ObjectDefinition(Dict.t<definitionNode>)
  | ArrayDefinition(Dict.t<definitionNode>)
  | GroupDefinition({idColumn: Schema.Column.unknownColumn, schema: Dict.t<definitionNode>})

/* type rec resultNode<'a> = Value('a) | Object(Dict.t<resultNode<'a>>) | Array(array<resultNode<'a>>) */

type resultNode<'a>

external valueToResultNode: 'a => resultNode<'a> = "%identity"
external objectToResultNode: Dict.t<resultNode<'a>> => resultNode<'a> = "%identity"
external arrayToResultNode: array<resultNode<'a>> => resultNode<'a> = "%identity"

let value = (value: 'a): 'a => {
  value->Obj.magic->ValueDefinition->Obj.magic
}

let column = (column: Schema.Column.t<'a, _>): 'a => {
  column->Schema.Column.toUnknownColumn->ColumnDefinition->Obj.magic
}

let optionalColumn = (columns: option<'a>, getColumn: 'a => Schema.Column.t<'b, _>): option<'b> => {
  columns->Option.getExn->getColumn->Schema.Column.toUnknownColumn->ColumnDefinition->Obj.magic
}

let object = (schema: 'schema): 'schema => {
  ObjectDefinition(Obj.magic(schema))->Obj.magic
}

let array = (schema: 'schema): array<'schema> => {
  ArrayDefinition(Obj.magic(schema))->Obj.magic
}

let optionalArray = (columns: option<'a>, getSchema: 'a => 'schema): array<'schema> => {
  let schema = columns->Option.getExn->getSchema

  ArrayDefinition(Obj.magic(schema))->Obj.magic
}

let group = (idColumn: 'a, schema: 'schema): array<'schema> => {
  GroupDefinition({idColumn: Obj.magic(idColumn), schema: Obj.magic(schema)})->Obj.magic
}

let optionalGroup = (columns: option<'a>, getIdColumn: 'a => Schema.Column.t<'b, _>, getSchema: 'a => 'schema): array<'schema> => {
  let idColumn = columns->Option.getExn->getIdColumn
  let schema = columns->Option.getExn->getSchema

  GroupDefinition({idColumn: Obj.magic(idColumn), schema: Obj.magic(schema)})->Obj.magic
}

let getFirstRow = rows => rows[0]->Option.getExn

let groupBy = (rows, idColumn) => {
  let rowsById = Map.make()

  Array.forEach(rows, row => {
    switch Dict.get(row, idColumn)->Option.getUnsafe->Obj.magic->Null.toOption {
    | Some(idValue) =>
      switch Map.get(rowsById, idValue) {
      | Some(rows) => Array.push(rows, row)
      | None => Map.set(rowsById, idValue, [row])
      }

    | None => ()
    }
  })

  rowsById->Map.values->Iterator.toArray
}

let maybeConvert = (value: Null.t<unknown>, column: Schema.Column.unknownColumn) => {
  value
  ->Null.toOption
  ->Option.map(value =>
    switch column.converter {
    | Some(converter) => Some(converter.dbToRes(value))
    | None => Some(value)
    }
  )
}

let rec nodeToValue = (rows: array<Dict.t<Null.t<_>>>, node) => {
  switch node {
  /* | ValueDefinition(columnName) => rows->getFirstRow->Dict.get(columnName)->valueToResultNode */
  | ColumnDefinition(column) =>
    rows
    ->getFirstRow
    ->Dict.get(`${column.table}_${column.name}`)
    ->Option.getUnsafe
    ->maybeConvert(column)
    ->valueToResultNode
  | ObjectDefinition(schema) => schemaToValues(rows, schema)
  | ArrayDefinition(schema) =>
    rows->Array.map(row => schemaToValues([row], schema))->arrayToResultNode
  | GroupDefinition({idColumn, schema}) =>
    groupBy(rows, `${idColumn.table}_${idColumn.name}`)
    ->Array.map(rows => schemaToValues(rows, schema))
    ->arrayToResultNode
  }
}
and schemaToValues = (rows, schema) => {
  schema
  ->Dict.toArray
  ->Array.map(((prop, node)) => (prop, nodeToValue(rows, node)))
  ->Dict.fromArray
  ->objectToResultNode
}

let nestIt = (rows: array<_>, def) => {
  /* switch def { */
  /* | ArrayDefinition({idColumn, schema}) => grouped(rows, idColumn, schema) */
  /* | _ => panic("only array definition is allowed as root") */
  /* } */

  nodeToValue(Obj.magic(rows), Obj.magic(def))->Obj.magic
}
