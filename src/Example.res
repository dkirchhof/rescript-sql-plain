open Index

module Artists = {
  type columns = {
    id: int,
    name: string,
  }

  type constraints = {pk: Constraint.t}

  let table = Table.make(
    "artists",
    {id: Column.integer({size: 10}), name: Column.varchar({size: 255})},
    columns => {
      pk: Constraint.primaryKey(columns.id),
    },
  )
}

module Albums = {
  type columns = {
    id: int,
    artistId: int,
    name: string,
    year: int,
  }

  type constraints = {pk: Constraint.t, fkArtist: Constraint.t}

  let table = Table.make(
    "albums",
    {
      id: Column.integer({size: 10}),
      artistId: Column.integer({size: 10}),
      name: Column.varchar({size: 255}),
      year: Column.integer({size: 10}),
    },
    columns => {
      pk: Constraint.primaryKey(Artists.table.columns.name),
      fkArtist: Constraint.foreignKey(
        ~ownColumn=columns.artistId,
        ~foreignColumn=Artists.table.columns.id,
        ~onUpdate=Constraint.RESTRICT,
        ~onDelete=Constraint.CASCADE,
      ),
    },
  )
}

module Songs = {
  type columns = {
    id: int,
    albumId: int,
    name: string,
    duration: string,
  }

  type constraints = {pk: Constraint.t, fkAlbum: Constraint.t}

  let table = Table.make(
    "songs",
    {
      id: Column.integer({size: 10}),
      albumId: Column.integer({size: 10}),
      name: Column.varchar({size: 255}),
      duration: Column.varchar({size: 255}),
    },
    columns => {
      pk: Constraint.primaryKey(Artists.table.columns.name),
      fkAlbum: Constraint.foreignKey(
        ~ownColumn=columns.albumId,
        ~foreignColumn=Albums.table.columns.id,
        ~onUpdate=Constraint.RESTRICT,
        ~onDelete=Constraint.CASCADE,
      ),
    },
  )
}

Js.log(DDL.toSQL(Artists.table))
Js.log(DDL.toSQL(Albums.table))
Js.log(DDL.toSQL(Songs.table))

open SelectQueryBuilder
open Expr

/* from(Albums.table)->select(a => {"id": a.id})->Js.log */

/* from(Albums.table) */
/* ->join1(Songs.table, Inner, ((album, song)) => eq(song.albumId, album.id)) */
/* ->where(((album, song)) => eq(album.id, song.id)) */
/* ->select(((album, song)) => {"albumId": album.id, "songId": song.id}) */
/* ->Js.log */

/* from(Albums.table) */
/* ->join1(Songs.table, Inner, ((album, song)) => eq(song.albumId, album.id)) */
/* ->where(((album, song)) => eq(album.id, song.id)) */
/* ->select(((album, song)) => {"albumId": album.id, "songId": song.id}) */
/* ->Js.log */

/* from(Artists.table) */
/* ->join1(Albums.table, Left, ((artist, album)) => eq(album.artistId, artist.id)) */
/* ->join2(Songs.table, Left, ((_artist, album, song)) => eq(song.albumId, album.id)) */
/* ->select(((artist, album, song)) => {"artistId": artist.id, "albumId": album.id, "songId": song.id}) */
/* ->Js.log */

let q = from(Artists.table)
->join1(Albums.table, Left, ((artist, album)) => eq(album.artistId, artist.id))
->select(((artist, album)) => {
    "id": artist.id,
    "name": artist.name,
    "albums": [
      {
        "id": album.id,
        "name": album.name,
        "artistId": artist.id,
      },
    ],
  }
)

type row = {
  "0_id": int,
  "0_name": string,
  "1_id": int,
  "1_name": string,
}

let rows: array<row> = [
  {
    "0_id": 1,
    "0_name": "Architects",
    "1_id": 1,
    "1_name": "Hollow Crown",
  }->Obj.magic,
  {
    "0_id": 1,
    "0_name": "Architects",
    "1_id": 2,
    "i_name": "Lost Forever / Lost Together",
  }->Obj.magic,
  {
    "0_id": 2,
    "0_name": "While She Sleeps",
    "1_id": Js.null,
    "1_name": Js.null,
  }->Obj.magic,
]

let result = q->SelectQueryBuilder.mapResult(rows)

%%raw(`
  import { inspect } from "util";

  // console.log(inspect(q, false, 5, true));
  console.log(inspect(result, false, 5, true));
`)

// type song = {
//   id: int,
//   albumId: int,
//   name: string,
// }

// type albumWithSongs = {
//   id: int,
//   artistId: int,
//   name: string,
//   songs: array<song>,
// }

// type artistWithAlbums = {
//   id: int,
//   name: string,
//   albumsWithSongs: array<albumWithSongs>,
// }

// let createMapper: ('a => 'b) => 'b = %raw(`
//   function(cb) {
//     const proxy = new Proxy({}, {
//       get(_, prop) {
//         return prop;
//       },
//     });

//     return cb(proxy);
//   }
// `)

/* let mapper = createMapper((row: row) => { */
/*   id: row["artistId"], */
/*   name: row["artistName"], */
/*   albumsWithSongs: [ */
/*     { */
/*       id: row["albumId"], */
/*       artistId: row["artistId"], */
/*       name: row["albumName"], */
/*       songs: [ */
/*         { */
/*           id: row["songId"], */
/*           albumId: row["albumId"], */
/*           name: row["songName"], */
/*         }, */
/*       ], */
/*     }, */
/*   ], */
/* }) */

/* let mapper2 = createMapper2(((artist: Artists.columns, album: Albums.columns)) => */
/*   { */
/*     "id": artist.id, */
/*     "name": artist.name, */
/*     "albums": [ */
/*       { */
/*         "id": album.id, */
/*         "artistId": artist.id, */
/*       }, */
/*     ], */
/*   } */
/* ) */

/* Js.log(mapper2) */

/* let getValues = obj => { */
/*   let result = Belt.MutableSet.String.make() */

/*   let rec getValuesRec = obj => { */
/*     Js.Dict.values(obj->Obj.magic)->Js.Array2.forEach(value => { */
/*       if Js.Types.test(value, Js.Types.String) { */
/*         Belt.MutableSet.String.add(result, value->Obj.magic) */
/*       } else if Js.Array2.isArray(value) { */
/*         getValuesRec(value[0]) */
/*       } */
/*     }) */

/*   } */

/*   getValuesRec(obj) */

/*   result->Belt.MutableSet.String.toArray */
/* } */

/* mapper2->getValues->Js.log */

// insertInto...values(default => { ...default, name: 'Test' })
