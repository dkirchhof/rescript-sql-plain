%%raw(`
  import { inspect } from "util";
`)

let log: 'a => unit = %raw(`
  function log(message) {
    console.log(inspect(message, false, 10, true));
  }
`)

type rec definitionNode<'a> =
  | ValueDefinition('a)
  | ColumnDefinition(Schema.Column.t<'a, 'a>)
  | ObjectDefinition(Dict.t<definitionNode<'a>>)
  | ArrayDefinition(Dict.t<definitionNode<'a>>)
  | GroupDefinition({idColumn: Schema.Column.t<'a, 'a>, schema: Dict.t<definitionNode<'a>>})

/* type rec resultNode<'a> = Value('a) | Object(Dict.t<resultNode<'a>>) | Array(array<resultNode<'a>>) */

type resultNode<'a>

external valueToResultNode: 'a => resultNode<'a> = "%identity"
external objectToResultNode: Dict.t<resultNode<'a>> => resultNode<'a> = "%identity"
external arrayToResultNode: array<resultNode<'a>> => resultNode<'a> = "%identity"

let value = (value: 'a): 'a => {
  ValueDefinition(Obj.magic(value))->Obj.magic
}

let column = (column: 'a): 'a => {
  ColumnDefinition(Obj.magic(column))->Obj.magic
}

let object = (schema: 'schema): 'schema => {
  ObjectDefinition(Obj.magic(schema))->Obj.magic
}

let array = (schema: 'schema): 'schema => {
  ArrayDefinition(Obj.magic(schema))->Obj.magic
}

let group = (idColumn: 'a, schema: 'schema): 'schema => {
  GroupDefinition({idColumn: Obj.magic(idColumn), schema: Obj.magic(schema)})->Obj.magic
}

type row = {
  artist_id: int,
  artist_name: string,
  genre_id: int,
  genre_name: string,
  album_id: int,
  album_name: string,
  song_id: int,
  song_name: string,
}

let rows = [
  {
    artist_id: 1,
    artist_name: "artist 1",
    genre_id: 1,
    genre_name: "genre 1",
    album_id: 1,
    album_name: "album 1",
    song_id: 1,
    song_name: "song 1",
  },
  {
    artist_id: 1,
    artist_name: "artist 1",
    genre_id: 1,
    genre_name: "genre 1",
    album_id: 1,
    album_name: "album 1",
    song_id: 2,
    song_name: "song 2",
  },
  {
    artist_id: 1,
    artist_name: "artist 1",
    genre_id: 1,
    genre_name: "genre 1",
    album_id: 2,
    album_name: "album 2",
    song_id: 3,
    song_name: "song 3",
  },
  {
    artist_id: 2,
    artist_name: "artist 2",
    genre_id: 1,
    genre_name: "genre 1",
    album_id: 3,
    album_name: "album 3",
    song_id: 4,
    song_name: "song 4",
  },
]

let row: 'row = %raw(`
  new Proxy({}, {
    get(_, prop) {
      return prop;
    },
  })
`)

/* let def = value(row.artist_id) */
/* let def = value(row.artist_name) */
/* let def = object({"id": value(row.artist_id), "name": value(row.artist_name)}) */

let def = group(
  row.artist_id,
  {
    "id": value(row.artist_id),
    "name": value(row.artist_name),
    "genre": object({"id": value(row.genre_id), "name": value(row.genre_name)}),
    "albums": group(
      row.album_id,
      {
        "id": value(row.album_id),
        "name": value(row.album_name),
        "songs": group(row.song_id, {"id": value(row.song_id), "name": value(row.song_name)}),
      },
    ),
  },
)

// get all rows with same artist_id
// get all rows of last step with same album_id
// get all rows of last step with same song_id

let getFirstRow = rows => rows[0]->Option.getExn

let groupBy = (rows, idColumn) => {
  let rowsById = Map.make()

  Array.forEach(rows, row => {
    switch Dict.get(row, idColumn)->Option.getUnsafe->Null.toOption {
    | Some(idValue) =>
      switch Map.get(rowsById, idValue) {
      | Some(rows) => Array.push(rows, row)
      | None => Map.set(rowsById, idValue, [row])
      }

    | None => ()
    }
  })

  rowsById
}

let rec nodeToValue = (rows, node) => {
  switch node {
  | ValueDefinition(columnName) => rows->getFirstRow->Dict.get(columnName)->valueToResultNode
  | ColumnDefinition(column) =>
    rows->getFirstRow->Dict.get(`${column.table}_${column.name}`)->valueToResultNode
  | ObjectDefinition(schema) => schemaToValues(rows, schema)
  | ArrayDefinition(schema) => schemaToValues(rows, schema)
  | GroupDefinition({idColumn, schema}) =>
    groupBy(rows, `${idColumn.table}_${idColumn.name}`)
    ->Map.values
    ->Iterator.toArray
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

let nestIt = (rows: array<{..}>, def) => {
  /* switch def { */
  /* | ArrayDefinition({idColumn, schema}) => grouped(rows, idColumn, schema) */
  /* | _ => panic("only array definition is allowed as root") */
  /* } */
  nodeToValue(Obj.magic(rows), Obj.magic(def))
}

nestIt(rows->Obj.magic, def->Obj.magic)->log
