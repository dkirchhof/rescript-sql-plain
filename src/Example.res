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
let o = Belt.Option.map

from(Albums.table)->select(a => {"id": a.id})->Js.log

from(Albums.table)
->innerJoin1(Songs.table)
->where(((album, song)) => eq(album.id, song.id))
->select(((album, song)) => {"albumId": album.id, "songId": song.id})
->Js.log

from(Albums.table)
->leftJoin1(Songs.table)
->where(((album, song)) => eq(album.id, song.id))
/* ->select(((album, song)) => {"albumId": album.id, "songId": o(song, s => s.id)}) */
->select(((album, song)) => o(song, s => {"albumId": album.id, "songId": s.id}))
->Js.log

/* Albums.table->make->leftJoin1(Songs.table)->leftJoin2(Songs.table)->Js.log //select(((albums, songs)) => {albumId: albums.id, songId: songs.id})->toSQL->Js.log */
