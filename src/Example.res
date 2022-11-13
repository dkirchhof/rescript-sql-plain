%%raw(`
  import { inspect } from "util";
`)

let log: 'a => unit = %raw(`
  function log(message) {
    if (typeof message === "string") {
      console.log(message);
    } else {
      console.log(inspect(message, false, 5, true));
    }
  }
`)

let connection = SQLite3.createConnection("test.db")

module Artists = {
  type columns = {
    id: int,
    name: string,
  }

  type constraints = {pk: Schema.Constraint.t}

  let table = Schema.Table.make(
    "artists",
    {id: Schema.Column.integer({size: 10}), name: Schema.Column.varchar({size: 255})},
    columns => {
      pk: Schema.Constraint.primaryKey(columns.id),
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

  type constraints = {pk: Schema.Constraint.t, fkArtist: Schema.Constraint.t}

  let table = Schema.Table.make(
    "albums",
    {
      id: Schema.Column.integer({size: 10}),
      artistId: Schema.Column.integer({size: 10}),
      name: Schema.Column.varchar({size: 255}),
      year: Schema.Column.integer({size: 10}),
    },
    columns => {
      pk: Schema.Constraint.primaryKey(columns.id),
      fkArtist: Schema.Constraint.foreignKey(
        ~ownColumn=columns.artistId,
        ~foreignColumn=Artists.table.columns.id,
        ~onUpdate=Schema.Constraint.FKStrategy.Restrict,
        ~onDelete=Schema.Constraint.FKStrategy.Cascade,
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

  type constraints = {pk: Schema.Constraint.t, fkAlbum: Schema.Constraint.t}

  let table = Schema.Table.make(
    "songs",
    {
      id: Schema.Column.integer({size: 10}),
      albumId: Schema.Column.integer({size: 10}),
      name: Schema.Column.varchar({size: 255}),
      duration: Schema.Column.varchar({size: 255}),
    },
    columns => {
      pk: Schema.Constraint.primaryKey(columns.id),
      fkAlbum: Schema.Constraint.foreignKey(
        ~ownColumn=columns.albumId,
        ~foreignColumn=Albums.table.columns.id,
        ~onUpdate=Schema.Constraint.FKStrategy.Restrict,
        ~onDelete=Schema.Constraint.FKStrategy.Cascade,
      ),
    },
  )
}

module Users = {
  type columns = {id: int, name: string}
  type constraints = {pk: Schema.Constraint.t}

  let table = Schema.Table.make(
    "users",
    {
      id: Schema.Column.integer({size: 10}),
      name: Schema.Column.varchar({size: 10}),
    },
    columns => {
      pk: Schema.Constraint.primaryKey(columns.id),
    },
  )
}

module Favorites = {
  type columns = {songId: int, userId: int}
  type constraints = {
    pk: Schema.Constraint.t,
    fkSong: Schema.Constraint.t,
    fkUser: Schema.Constraint.t,
  }

  let table = Schema.Table.make(
    "favorites",
    {
      songId: Schema.Column.integer({size: 10}),
      userId: Schema.Column.integer({size: 10}),
    },
    columns => {
      pk: Schema.Constraint.primaryKey((columns.songId, columns.userId)),
      fkSong: Schema.Constraint.foreignKey(
        ~ownColumn=columns.songId,
        ~foreignColumn=Songs.table.columns.id,
        ~onUpdate=Schema.Constraint.FKStrategy.Restrict,
        ~onDelete=Schema.Constraint.FKStrategy.Cascade,
      ),
      fkUser: Schema.Constraint.foreignKey(
        ~ownColumn=columns.userId,
        ~foreignColumn=Users.table.columns.id,
        ~onUpdate=Schema.Constraint.FKStrategy.Restrict,
        ~onDelete=Schema.Constraint.FKStrategy.Cascade,
      ),
    },
  )
}

let createTables = () => {
  open CreateTableQueryBuilder

  createTable(Artists.table)->SQL.fromCreateTableQuery->log
  createTable(Albums.table)->SQL.fromCreateTableQuery->log
  createTable(Songs.table)->SQL.fromCreateTableQuery->log
  createTable(Users.table)->SQL.fromCreateTableQuery->log
  createTable(Favorites.table)->SQL.fromCreateTableQuery->log
}

let selectNameFromArtist1 = () => {
  open SelectQueryBuilder
  open Expr

  let q =
    from(Artists.table)->where(artist => eq(artist.id, 1))->select(artist => {"name": artist.name})

  let sql = SQL.fromSelectQuery(q)
  let mapper = mapOne(q)

  let result = connection->SQLite3.prepare(sql)->SQLite3.get->Belt.Option.map(mapper)

  log(sql)
  log(result)
}

let selectArtistsWithAlbumsWithSongs = () => {
  open SelectQueryBuilder
  open Expr

  let q =
    from(Artists.table)
    ->join1(Albums.table, Left, ((artist, album)) => eq(album.artistId, artist.id))
    ->join2(Songs.table, Left, ((_artist, album, song)) => eq(song.albumId, album.id))
    ->select(((artist, album, song)) => {
      "id": artist.id,
      "name": artist.name,
      "albums": [
        {
          "id": album.id,
          "name": album.name,
          "songs": [
            {
              "id": song.id,
              "name": song.name,
            },
          ],
        },
      ],
    })

    let sql = SQL.fromSelectQuery(q)
    let mapper = mapMany(q)

    let result = connection->SQLite3.prepare(sql)->SQLite3.all->mapper

    log(sql)
    log(result)
}

createTables()
selectNameFromArtist1()
selectArtistsWithAlbumsWithSongs()

/* // insertInto...values(default => { ...default, name: 'Test' }) */
