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

/* Js.log(DDL.toSQL(Artists.table)) */
/* Js.log(DDL.toSQL(Albums.table)) */
/* Js.log(DDL.toSQL(Songs.table)) */

open SelectQueryBuilder
open Expr

from(Albums.table)
->where(a => eq(a.id, 1))
->select(a => {"id": a.id})
->SelectQueryBuilder.toSQL
->Js.log

type song = {
  id: int,
  name: string,
}

type album = {
  id: int,
  name: string,
  songs: array<song>,
}

type artistWithAlbums = {
  id: int,
  name: string,
  albums: array<album>,
}

let q =
  from(Artists.table)
  ->join1(Albums.table, Left, ((artist, album)) => eq(album.artistId, artist.id))
  ->join2(Songs.table, Left, ((_artist, album, song)) => eq(song.albumId, album.id))
  ->where(((artist, _album, _song)) => eq(artist.id, 1))
  ->select(((artist, album, song)) => {
    id: artist.id,
    name: artist.name,
    albums: [
      {
        id: album.id,
        name: album.name,
        songs: [
          {
            id: song.id,
            name: song.name,
          },
        ],
      },
    ],
  })

let connection = SQLite3.createConnection("test.db")
let sql = q->SelectQueryBuilder.toSQL

Js.log(sql)

let row = connection->SQLite3.prepare(sql)->SQLite3.get
let rows = connection->SQLite3.prepare(sql)->SQLite3.all

let result1 = row->Belt.Option.map(row => q->SelectQueryBuilder.mapOne(row))
let result2 = q->SelectQueryBuilder.mapMany(rows)

%%raw(`
  import { inspect } from "util";

  // console.log(inspect(q, false, 5, true));
  console.log(inspect(result1, false, 5, true));
  console.log(inspect(result2, false, 5, true));
`)

// insertInto...values(default => { ...default, name: 'Test' })
