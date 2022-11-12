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

from(Albums.table)->select(a => {"id": a.id})->Js.log

from(Albums.table)
->join1(Songs.table, Inner, ((album, song)) => eq(song.albumId, album.id))
->where(((album, song)) => eq(album.id, song.id))
->select(((album, song)) => {"albumId": album.id, "songId": song.id})
->Js.log

from(Albums.table)
->join1(Songs.table, Inner, ((album, song)) => eq(song.albumId, album.id))
->where(((album, song)) => eq(album.id, song.id))
->select(((album, song)) => {"albumId": album.id, "songId": song.id})
->Js.log

from(Artists.table)
->join1(Albums.table, Left, ((artist, album)) => eq(album.artistId, artist.id))
->join2(Songs.table, Left, ((_artist, album, song)) => eq(song.albumId, album.id))
->select(((artist, album, song)) => {"artistId": artist.id, "albumId": album.id, "songId": song.id})
->Js.log

from(Artists.table)
->join1(Albums.table, Left, ((artist, album)) => eq(album.artistId, artist.id))
->select(((artist, album)) =>
  {
    "artistId": artist.id,
    "artistName": artist.name,
    "albumId": album.id,
    "albumName": album.name,
    "albumYear": album.year,
  }
)
->Js.log

type row = {
  "artistId": int,
  "artistName": string,
  "albumId": int,
  "albumName": string,
  "songId": int,
  "songName": string,
}

let rows: array<row> = [
  {
    "artistId": 1,
    "artistName": "Architects",
    "albumId": 1,
    "albumName": "Hollow Crown",
    "songId": 1,
    "songName": "Erstes Lied",
  }->Obj.magic,
  {
    "artistId": 1,
    "artistName": "Architects",
    "albumId": 2,
    "albumName": "Lost Forever / Lost Together",
    "songId": Js.null,
    "songName": Js.null,
  }->Obj.magic,
  {
    "artistId": 2,
    "artistName": "While She Sleeps",
    "albumId": Js.null,
    "albumName": Js.null,
    "songId": Js.null,
    "songName": Js.null,
  }->Obj.magic,
]

rows->Js.log

type song = {
  id: int,
  albumId: int,
  name: string,
}

type albumWithSongs = {
  id: int,
  artistId: int,
  name: string,
  songs: array<song>,
}

type artistWithAlbums = {
  id: int,
  name: string,
  albumsWithSongs: array<albumWithSongs>,
}

let createMapper: ('a => 'b) => 'b = %raw(`
  function(cb) {
    const proxy = new Proxy({}, {
      get(_, prop) {
        return prop;
      },
    });

    return cb(proxy);
  }
`)

let mapper = createMapper((row: row) => [
  {
    id: row["artistId"],
    name: row["artistName"],
    albumsWithSongs: [
      {
        id: row["albumId"],
        artistId: row["artistId"],
        name: row["albumName"],
        songs: [
          {
            id: row["songId"],
            albumId: row["albumId"],
            name: row["songName"],
          },
        ],
      },
    ],
  },
])

%%raw(`
  import { inspect } from "util";
  import nesthydration from 'nesthydrationjs';

  const result = nesthydration().nest(rows, mapper);

  console.log(inspect(result, false, 5, true));
`)

// insertInto...values(default => { ...default, name: 'Test' })
