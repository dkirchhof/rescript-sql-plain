%%raw(`
  import { inspect } from "util";
`)

let log: 'a => unit = %raw(`
  function log(message) {
    console.log(inspect(message, false, 10, true));
  }
`)

type rec definitionNode =
  | ValueDefinition(string)
  | ObjectDefinition(Dict.t<definitionNode>)
  | ArrayDefinition({idColumn: string, schema: Dict.t<definitionNode>})

/* type rec resultNode<'a> = Value('a) | Object(Dict.t<resultNode<'a>>) | Array(array<resultNode<'a>>) */

type resultNode<'a>

external valueToResultNode: 'a => resultNode<'a> = "%identity"
external objectToResultNode: Dict.t<resultNode<'a>> => resultNode<'a> = "%identity"
external arrayToResultNode: array<resultNode<'a>> => resultNode<'a> = "%identity"

let value = (value: 'a): 'a => {
  ValueDefinition(Obj.magic(value))->Obj.magic
}

let object = (schema: 'schema): 'schema => {
  ObjectDefinition(Obj.magic(schema))->Obj.magic
}

let array = (idColumn, schema: 'schema): 'schema => {
  ArrayDefinition({idColumn: Obj.magic(idColumn), schema: Obj.magic(schema)})->Obj.magic
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

let def = array(
  row.artist_id,
  {
    "id": value(row.artist_id),
    "name": value(row.artist_name),
    "genre": object({"id": value(row.genre_id), "name": value(row.genre_name)}),
    "albums": array(
      row.album_id,
      {
        "id": value(row.album_id),
        "name": value(row.album_name),
        "songs": array(row.song_id, {"id": value(row.song_id), "name": value(row.song_name)}),
      },
    ),
  },
)

/* let def2 = ArrayDefinition({ */
/* idColumn: "artist_id", */
/* schema: { */
/* "id": ValueDefinition("artist_id"), */
/* "name": ValueDefinition("artist_name"), */
/* "genre": ObjectDefinition( */
/* { */
/* "id": ValueDefinition("genre_id"), */
/* "name": ValueDefinition("genre_name"), */
/* }->Obj.magic, */
/* ), */
/* "albums": ArrayDefinition({ */
/* idColumn: "album_id", */
/* schema: { */
/* "id": ValueDefinition("album_id"), */
/* "name": ValueDefinition("album_name"), */
/* "songs": ArrayDefinition({ */
/* idColumn: "song_id", */
/* schema: { */
/* "id": ValueDefinition("song_id"), */
/* "name": ValueDefinition("song_name"), */
/* }->Obj.magic, */
/* }), */
/* }->Obj.magic, */
/* }), */
/* }->Obj.magic, */
/* }) */

/* Console.log(def == Obj.magic(def2)) */

// get all rows with same artist_id
// get all rows of last step with same album_id
// get all rows of last step with same song_id

let getFirstRow = rows => rows[0]->Option.getExn

let groupBy = (rows, idColumn) => {
  let rowsById = Map.make()

  Array.forEach(rows, row => {
    let idValue = Dict.get(row, idColumn)

    switch Map.get(rowsById, idValue) {
    | Some(rows) => Array.push(rows, row)
    | None => Map.set(rowsById, idValue, [row])
    }
  })

  rowsById
}

let rec nodeToValue = (rows, node) => {
  switch node {
  | ValueDefinition(columnName) => rows->getFirstRow->Dict.get(columnName)->valueToResultNode
  | ObjectDefinition(schema) => schemaToValues(rows, schema)
  | ArrayDefinition({idColumn, schema}) =>
    groupBy(rows, idColumn)
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

let nestIt = (rows, def) => {
  /* switch def { */
  /* | ArrayDefinition({idColumn, schema}) => grouped(rows, idColumn, schema) */
  /* | _ => panic("only array definition is allowed as root") */
  /* } */
  nodeToValue(rows, def)
}

nestIt(rows->Obj.magic, def->Obj.magic)->log
