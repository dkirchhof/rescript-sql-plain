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

let connection = SQLite3.createConnection(":memory:")

module Artists = {
  type columns = {
    id: int,
    name: string,
  }

  type constraints = {pk: Schema.Constraint.t<int>}

  let table = Schema.Table.make(
    "artists",
    {
      id: Schema.Column.integer({size: 10}),
      name: Schema.Column.varchar({size: 255}),
    },
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

  type constraints = {pk: Schema.Constraint.t<int>, fkArtist: Schema.Constraint.t<int>}

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

  type constraints = {pk: Schema.Constraint.t<int>, fkAlbum: Schema.Constraint.t<int>}

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
  type columns = {
    id: int,
    name: string,
  }

  type constraints = {pk: Schema.Constraint.t<int>}

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
  type columns = {
    songId: int,
    userId: int,
    likedAt: Js.Date.t,
  }

  type constraints = {
    pk: Schema.Constraint.t<int>,
    fkSong: Schema.Constraint.t<int>,
    fkUser: Schema.Constraint.t<int>,
  }

  let table = Schema.Table.make(
    "favorites",
    {
      songId: Schema.Column.integer({}),
      userId: Schema.Column.integer({}),
      likedAt: Schema.Column.date({}),
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
  open QueryBuilder.CreateTable

  let q1 = createTable(Artists.table)->SQL.fromCreateTableQuery
  let q2 = createTable(Albums.table)->SQL.fromCreateTableQuery
  let q3 = createTable(Songs.table)->SQL.fromCreateTableQuery
  let q4 = createTable(Users.table)->SQL.fromCreateTableQuery
  let q5 = createTable(Favorites.table)->SQL.fromCreateTableQuery

  log(q1)
  log("")

  log(q2)
  log("")

  log(q3)
  log("")
  log(q4)
  log("")

  log(q5)
  log("")

  SQLite3.exec(connection, q1)
  SQLite3.exec(connection, q2)
  SQLite3.exec(connection, q3)
  SQLite3.exec(connection, q4)
  SQLite3.exec(connection, q5)
}

let insertData = () => {
  open QueryBuilder.Insert

  let q1 =
    insertInto(Artists.table)
    ->values([
      {id: 1, name: "Architects"},
      {id: 2, name: "While She Sleeps"},
      {id: 3, name: "Misfits"},
      {id: 4, name: "Iron Maiden"},
      {id: 5, name: "UPDATEME"},
    ])
    ->SQL.fromInsertQuery

  let q2 =
    insertInto(Albums.table)
    ->values([
      {id: 1, artistId: 1, name: "Hollow Crown", year: 2009},
      /* {id: 2, artistId: 1, name: "Lost Forever / Lost Together", year: 2014}, */
      /* {id: 3, artistId: 2, name: "This Is the Six", year: 2012}, */
      /* {id: 4, artistId: 2, name: "Brainwashed", year: 2015}, */
      /* {id: 5, artistId: 2, name: "You Are We", year: 2017}, */
      /* {id: 6, artistId: 2, name: "So What?", year: 2019}, */
      /* {id: 7, artistId: 3, name: "Static Age", year: 1978}, */
      /* {id: 8, artistId: 3, name: "Walk Among Us", year: 1982}, */
      /* {id: 9, artistId: 3, name: "American Psycho", year: 1997}, */
      /* {id: 10, artistId: 4, name: "Iron Maiden", year: 1980}, */
      /* {id: 11, artistId: 4, name: "The Number of the Beast", year: 1982}, */
      /* {id: 12, artistId: 4, name: "Fear of the Dark", year: 1992}, */
    ])
    ->SQL.fromInsertQuery

  let q3 =
    insertInto(Songs.table)
    ->values([
      {
        id: 1,
        albumId: 1,
        name: "Early Grave",
        duration: "3:32",
      },
      /* {id: 2, albumId: 1, name: "Dethroned", duration: "3:06"}, */
      /* {id: 3, albumId: 1, name: "Numbers Count for Nothing", duration: "3:50"}, */
      /* {id: 4, albumId: 1, name: "Follow the Water", duration: "3:40"}, */
      /* {id: 5, albumId: 1, name: "In Elegance", duration: "4:16"}, */
      /* {id: 6, albumId: 1, name: "We're All Alone", duration: "3:01"}, */
      /* {id: 7, albumId: 1, name: "Borrowed Time", duration: "2:30"}, */
      /* {id: 8, albumId: 1, name: "Every Last Breath", duration: "3:28"}, */
      /* {id: 9, albumId: 1, name: "One of These Days", duration: "2:34"}, */
      /* {id: 10, albumId: 1, name: "Dead March", duration: "3:47"}, */
      /* {id: 11, albumId: 1, name: "Left with a Last Minute", duration: "2:57"}, */
      /* {id: 12, albumId: 1, name: "Hollow Crown", duration: "4:24"}, */
      /* {id: 13, albumId: 2, name: "Gravedigger", duration: "4:05"}, */
      /* {id: 14, albumId: 2, name: "Naysayer", duration: "3:25"}, */
      /* {id: 15, albumId: 2, name: "Broken Cross", duration: "3:52"}, */
      /* {id: 16, albumId: 2, name: "The Devil Is Near", duration: "3:35"}, */
      /* {id: 17, albumId: 2, name: "Dead Man Talking", duration: "4:04"}, */
      /* {id: 18, albumId: 2, name: "Red Hypergiant", duration: "2:13"}, */
      /* {id: 19, albumId: 2, name: "C.A.N.C.E.R", duration: "4:19"}, */
      /* {id: 20, albumId: 2, name: "Colony Collapse", duration: "4:31"}, */
      /* {id: 21, albumId: 2, name: "Castles in the Air", duration: "3:42"}, */
      /* {id: 22, albumId: 2, name: "Youth Is Wasted on the Young", duration: "4:23"}, */
      /* {id: 23, albumId: 2, name: "The Distant Blue", duration: "5:13"}, */
      /* {id: 24, albumId: 3, name: "Dead Behind the Eyes", duration: "4:04"}, */
      /* {id: 25, albumId: 3, name: "False Freedom", duration: "3:47"}, */
      /* {id: 26, albumId: 3, name: "Satisfied in Suffering", duration: "3:13"}, */
      /* {id: 27, albumId: 3, name: "Seven Hills", duration: "4:20"}, */
      /* {id: 28, albumId: 3, name: "Our Courage, Our Cancer", duration: "3:34"}, */
      /* {id: 29, albumId: 3, name: "This Is the Six", duration: "4:44"}, */
      /* {id: 30, albumId: 3, name: "The Chapel", duration: "2:15"}, */
      /* {id: 31, albumId: 3, name: "Be(lie)ve", duration: "3:54"}, */
      /* {id: 32, albumId: 3, name: "Until the Death", duration: "4:26"}, */
      /* {id: 33, albumId: 3, name: "Love at War", duration: "4:43"}, */
      /* {id: 34, albumId: 3, name: "The Plague of a New Age", duration: "4:18"}, */
      /* {id: 35, albumId: 3, name: "Reunite", duration: "1:14"}, */
      /* {id: 36, albumId: 4, name: "The Divide", duration: "0:52"}, */
      /* {id: 37, albumId: 4, name: "New World Torture", duration: "4:40"}, */
      /* {id: 38, albumId: 4, name: "Brainwashed", duration: "3:28"}, */
      /* {id: 39, albumId: 4, name: "Our Legacy", duration: "4:07"}, */
      /* {id: 40, albumId: 4, name: "Four Walls", duration: "5:07"}, */
      /* {id: 41, albumId: 4, name: "Torment", duration: "3:48"}, */
      /* {id: 42, albumId: 4, name: "Kangaezu Ni", duration: "1:21"}, */
      /* {id: 43, albumId: 4, name: "Life in Tension", duration: "3:41"}, */
      /* {id: 44, albumId: 4, name: "Trophies of Violence", duration: "5:01"}, */
      /* {id: 45, albumId: 4, name: "No Sides, No Enemies", duration: "5:05"}, */
      /* {id: 46, albumId: 4, name: "Method in Madness", duration: "3:54"}, */
      /* {id: 47, albumId: 4, name: "Modern Minds", duration: "4:49"}, */
      /* {id: 48, albumId: 5, name: "You Are We", duration: "4:47"}, */
      /* {id: 49, albumId: 5, name: "Steal the Sun", duration: "4:37"}, */
      /* {id: 50, albumId: 5, name: "Feel", duration: "4:39"}, */
      /* {id: 51, albumId: 5, name: "Empire of Silence", duration: "4:23"}, */
      /* {id: 52, albumId: 5, name: "Wide Awake", duration: "5:04"}, */
      /* {id: 53, albumId: 5, name: "Silence Speaks", duration: "4:55"}, */
      /* {id: 54, albumId: 5, name: "Settle Down Society", duration: "4:56"}, */
      /* {id: 55, albumId: 5, name: "Hurricane", duration: "4:43"}, */
      /* {id: 56, albumId: 5, name: "Revolt", duration: "3:57"}, */
      /* {id: 57, albumId: 5, name: "Civil Isolation", duration: "4:22"}, */
      /* {id: 58, albumId: 5, name: "In Another Now", duration: "4:35"}, */
      /* {id: 59, albumId: 6, name: "Anti-Social", duration: "4:14"}, */
      /* {id: 60, albumId: 6, name: "I've Seen It All", duration: "4:12"}, */
      /* {id: 61, albumId: 6, name: "Inspire", duration: "4:10"}, */
      /* {id: 62, albumId: 6, name: "So What?", duration: "4:32"}, */
      /* {id: 63, albumId: 6, name: "The Guilty Party", duration: "4:26"}, */
      /* {id: 64, albumId: 6, name: "Haunt Me", duration: "4:31"}, */
      /* {id: 65, albumId: 6, name: "Elephant", duration: "4:38"}, */
      /* {id: 66, albumId: 6, name: "Set You Free", duration: "4:17"}, */
      /* {id: 67, albumId: 6, name: "Good Grief", duration: "3:38"}, */
      /* {id: 68, albumId: 6, name: "Back of My Mind", duration: "4:27"}, */
      /* {id: 69, albumId: 6, name: "Gates of Paradise", duration: "5:20"}, */
      /* {id: 70, albumId: 7, name: "Static Age", duration: "1:47"}, */
      /* {id: 71, albumId: 7, name: "TV Casualty", duration: "2:24"}, */
      /* {id: 72, albumId: 7, name: "Some Kinda Hate", duration: "2:02"}, */
      /* {id: 73, albumId: 7, name: "Last Caress", duration: "1:57"}, */
      /* {id: 74, albumId: 7, name: "Return of the Fly", duration: "1:37"}, */
      /* {id: 75, albumId: 7, name: "Hybrid Moments", duration: "1:42"}, */
      /* {id: 76, albumId: 7, name: "We Are 138", duration: "1:41"}, */
      /* {id: 77, albumId: 7, name: "Teenagers from Mars", duration: "2:51"}, */
      /* {id: 78, albumId: 7, name: "Come Back", duration: "5:00"}, */
      /* {id: 79, albumId: 7, name: "Angelfuck", duration: "1:38"}, */
      /* {id: 80, albumId: 7, name: "Hollywood Babylon", duration: "2:20"}, */
      /* {id: 81, albumId: 7, name: "Attitude", duration: "1:31"}, */
      /* {id: 82, albumId: 7, name: "Bullet", duration: "1:38"}, */
      /* {id: 83, albumId: 7, name: "Theme for a Jackal", duration: "2:41"}, */
      /* {id: 84, albumId: 7, name: "She", duration: "1:24"}, */
      /* {id: 85, albumId: 7, name: "Spinal Remains", duration: "1:27"}, */
      /* {id: 86, albumId: 7, name: "In the Doorway", duration: "1:25"}, */
      /* {id: 87, albumId: 8, name: "20 Eyes", duration: "1:41"}, */
      /* {id: 88, albumId: 8, name: "I Turned into a Martian", duration: "1:41"}, */
      /* {id: 89, albumId: 8, name: "All Hell Breaks Loose", duration: "1:47"}, */
      /* {id: 90, albumId: 8, name: "Vampira", duration: "1:26"}, */
      /* {id: 91, albumId: 8, name: "Nike-A-Go-Go", duration: "2:16"}, */
      /* {id: 92, albumId: 8, name: "Hate Breeders", duration: "3:08"}, */
      /* {id: 93, albumId: 8, name: "Mommy, Can I Go Out and Kill Tonight?", duration: "2:01"}, */
      /* {id: 94, albumId: 8, name: "Night of the Living Dead", duration: "1:57"}, */
      /* {id: 95, albumId: 8, name: "Skulls", duration: "2:00"}, */
      /* {id: 96, albumId: 8, name: "Violent World", duration: "1:46"}, */
      /* {id: 97, albumId: 8, name: "Devils Whorehouse", duration: "1:45"}, */
      /* {id: 98, albumId: 8, name: "Astro Zombies", duration: "2:14"}, */
      /* {id: 99, albumId: 8, name: "Braineaters", duration: "0:56"}, */
      /* {id: 100, albumId: 9, name: "Abominable Dr. Phibes", duration: "1:41"}, */
      /* {id: 101, albumId: 9, name: "American Psycho", duration: "2:06"}, */
      /* {id: 102, albumId: 9, name: "Speak of the Devil", duration: "1:47"}, */
      /* {id: 103, albumId: 9, name: "Walk Among Us", duration: "1:23"}, */
      /* {id: 104, albumId: 9, name: "The Hunger", duration: "1:43"}, */
      /* {id: 105, albumId: 9, name: "From Hell They Came", duration: "2:16"}, */
      /* {id: 106, albumId: 9, name: "Dig Up Her Bones", duration: "3:01"}, */
      /* {id: 107, albumId: 9, name: "Blacklight", duration: "1:27"}, */
      /* {id: 108, albumId: 9, name: "Resurrection", duration: "1:29"}, */
      /* {id: 109, albumId: 9, name: "This Island Earth", duration: "2:15"}, */
      /* {id: 110, albumId: 9, name: "Crimson Ghost", duration: "2:01"}, */
      /* {id: 111, albumId: 9, name: "Day of the Dead", duration: "2:49"}, */
      /* {id: 112, albumId: 9, name: "The Haunting", duration: "1:25"}, */
      /* {id: 113, albumId: 9, name: "Mars Attacks", duration: "2:28"}, */
      /* {id: 114, albumId: 9, name: "Hate the Living, Love the Dead", duration: "2:36"}, */
      /* {id: 115, albumId: 9, name: "Shining", duration: "2:59"}, */
      /* {id: 116, albumId: 9, name: "Don't Open 'Til Doomsday + Hell Night", duration: "8:58"}, */
    ])
    ->SQL.fromInsertQuery

  let q4 = insertInto(Users.table)->values([{id: 1, name: "John Doe"}])->SQL.fromInsertQuery

  let q5 =
    insertInto(Favorites.table)
    ->values([
      {userId: 1, songId: 1, likedAt: Js.Date.fromString("2022-01-01")},
      /* {userId: 1, songId: 2, likedAt: Js.Date.fromString("2022-02-01")}, */
    ])
    ->SQL.fromInsertQuery

  log(q1)
  log("")

  log(q2)
  log("")

  log(q3)
  log("")

  log(q4)
  log("")

  log(q5)
  log("")

  SQLite3.exec(connection, q1)
  SQLite3.exec(connection, q2)
  SQLite3.exec(connection, q3)
  SQLite3.exec(connection, q4)
  SQLite3.exec(connection, q5)
}

let updateData = () => {
  open QueryBuilder.Update
  open QueryBuilder.Expr

  let q1 =
    update(Artists.table)
    ->set({
      id: skip,
      name: "DELETEME",
    })
    ->where(c => equal(c.name, "UPDATEME"))
    ->SQL.fromUpdateQuery

  log(q1)
  log("")

  SQLite3.exec(connection, q1)
}

let deleteData = () => {
  open QueryBuilder.Delete
  open QueryBuilder.Expr

  let q1 = deleteFrom(Artists.table)->where(c => equal(c.name, "DELETEME"))->SQL.fromDeleteQuery

  log(q1)
  log("")

  SQLite3.exec(connection, q1)
}

let selectNameFromArtist1 = () => {
  open QueryBuilder.Select
  open QueryBuilder.Expr

  let q =
    from(Artists.table)
    ->where(artist => equal(artist.id, 1))
    ->select(artist => {"name": artist.name})

  let sql = SQL.fromSelectQuery(q)

  log(sql)

  let mapper = map(q)
  let result = connection->SQLite3.prepare(sql)->SQLite3.get->Belt.Option.map(mapper)

  log(result)
}

/* let selectArtistsWithAlbumsWithSongs = () => { */
/* open QueryBuilder.Select */

/* let q = */
/* from(Artists.table) */
/* ->join1(Albums.table, Left, ((artist, album)) => (album.artistId, artist.id)) */
/* ->join2(Songs.table, Left, ((_artist, album, song)) => (song.albumId, album.id)) */
/* ->select(((artist, album, song)) => */
/* { */
/* "artistId": column(artist.id), */
/* "artistName": column(artist.name), */
/* "albumId": column(album.id), */
/* "albumName": column(album.name), */
/* "songId": column(song.id), */
/* "songName": column(song.name), */
/* } */
/* ) */

/* let sql = SQL.fromSelectQuery(q) */
/* log(sql) */

/* let mapper = map(q) */
/* let result = connection->SQLite3.prepare(sql)->SQLite3.all->Js.Array2.map(mapper) */

/* log(result) */
/* } */

/* let selectFavoritesOfUser1 = () => { */
/* open QueryBuilder.Select */

/* let q = */
/* from(Favorites.table) */
/* ->join1(Songs.table, Inner, ((favorite, song)) => (favorite.songId, song.id)) */
/* ->join2(Albums.table, Inner, ((_favorite, song, album)) => (song.albumId, album.id)) */
/* ->join3(Artists.table, Inner, ((_favorite, _song, album, artist)) => ( */
/* album.artistId, */
/* artist.id, */
/* )) */
/* ->select(((favorite, song, album, artist)) => */
/* { */
/* "songName": column(song.name), */
/* "albumName": column(album.name), */
/* "artistName": column(artist.name), */
/* "likedAt": column(favorite.likedAt), */
/* } */
/* ) */

/* let sql = SQL.fromSelectQuery(q) */
/* log(sql) */

/* let mapper = map(q) */
/* let result = connection->SQLite3.prepare(sql)->SQLite3.all->Js.Array2.map(mapper) */

/* log(result) */
/* } */

/* let expressionsTest = () => { */
/* open QueryBuilder.Select */
/* open QueryBuilder.Expr */

/* let expressions = [ */
/* (c: Artists.columns) => equal(c.id, Literal(1)), */
/* (c: Artists.columns) => notEqual(c.id, Literal(1)), */
/* (c: Artists.columns) => greaterThan(c.id, Literal(1)), */
/* (c: Artists.columns) => greaterThanEqual(c.id, Literal(1)), */
/* (c: Artists.columns) => lessThan(c.id, Literal(1)), */
/* (c: Artists.columns) => lessThanEqual(c.id, Literal(1)), */
/* (c: Artists.columns) => between(c.id, Literal(1), Literal(2)), */
/* (c: Artists.columns) => notBetween(c.id, Literal(1), Literal(2)), */
/* (c: Artists.columns) => in_(c.id, [Literal(1), Literal(2)]), */
/* (c: Artists.columns) => notIn(c.id, [Literal(1), Literal(2)]), */
/* (c: Artists.columns) => and_([equal(c.id, Literal(1)), notEqual(c.name, Literal("test"))]), */
/* (c: Artists.columns) => or([equal(c.id, Literal(1)), notEqual(c.name, Literal("test"))]), */
/* ] */

/* expressions->Js.Array2.forEach(expression => { */
/* from(Artists.table) */
/* ->where(expression) */
/* ->select(c => {"id": column(c.id)}) */
/* ->SQL.fromSelectQuery */
/* ->Js.log */

/* Js.log("") */
/* }) */
/* } */

/* let limitAndOffsetTest = () => { */
/* open QueryBuilder.Select */

/* from(Artists.table) */
/* ->limit(10) */
/* ->offset(5) */
/* ->select(c => {"id": column(c.id)}) */
/* ->SQL.fromSelectQuery */
/* ->Js.log */
/* Js.log("") */
/* } */

/* let orderByTest = () => { */
/* open QueryBuilder.Select */

/* from(Artists.table) */
/* ->addOrderBy(c => c.id, Asc) */
/* ->addOrderBy(c => c.name, Desc) */
/* ->select(c => {"id": column(c.id)}) */
/* ->SQL.fromSelectQuery */
/* ->Js.log */

/* Js.log("") */
/* } */

/* let groupByTest = () => { */
/* open QueryBuilder.Select */
/* open QueryBuilder.Expr */

/* from(Artists.table) */
/* ->addGroupBy(c => c.id) */
/* ->addGroupBy(c => c.name) */
/* ->having(c => equal(c.id, Literal(1))) */
/* ->select(c => {"id": column(c.id)}) */
/* ->SQL.fromSelectQuery */
/* ->Js.log */

/* Js.log("") */
/* } */

/* let subQueryTest = () => { */
/* open QueryBuilder.Select */
/* open QueryBuilder.Expr */
/* open SubQueryBuilder */

/* from(Artists.table) */
/* ->where(c => equal(c.id, from(Artists.table)->make(c => Agg.max(c.id)))) */
/* ->select(c => {"id": column(c.id)}) */
/* ->SQL.fromSelectQuery */
/* ->Js.log */

/* Js.log("") */
/* } */

/* let aggregationTest = () => { */
/* open QueryBuilder.Select */

/* let q = from(Artists.table)->select(c => */
/* { */
/* "count": Agg.count(c.name), */
/* "sum": Agg.sum(c.name), */
/* "avg": Agg.avg(c.name), */
/* "min": Agg.min(c.name), */
/* "max": Agg.max(c.name), */
/* } */
/* ) */

/* let sql = SQL.fromSelectQuery(q) */
/* log(sql) */

/* let mapper = map(q) */
/* let result = connection->SQLite3.prepare(sql)->SQLite3.all->Js.Array2.map(mapper) */

/* log(result) */
/* log("") */
/* } */

createTables()
insertData()
updateData()
deleteData()
/* selectNameFromArtist1() */
/* selectArtistsWithAlbumsWithSongs() */
/* selectFavoritesOfUser1() */
/* expressionsTest() */
/* limitAndOffsetTest() */
/* orderByTest() */
/* groupByTest() */
/* subQueryTest() */
/* aggregationTest() */
