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
let exec = sql =>  connection->SQLite3.exec(sql)->AsyncResult.ok
let getRows = sql => connection->SQLite3.prepare(sql)->SQLite3.all->AsyncResult.ok

module Artist = {
  type t = {
    id: int,
    name: string,
  }
}

module Album = {
  type t = {
    id: int,
    artist: Artist.t,
    name: string,
    year: int,
  }
}

module Song = {
  type t = {
    id: int,
    album: Album.t,
    name: string,
    duration: string,
  }
}

module User = {
  type t = {
    id: int,
    name: string,
  }
}

module Favorite = {
  type t = {
    song: Song.t,
    user: User.t,
    likedAt: Date.t,
  }
}

module ArtistWithAlbumsWithSongs = {
  type song = {
    id: int,
    name: string,
    duration: string,
  }

  type albumWithSongs = {
    id: int,
    name: string,
    year: int,
    songs: array<song>,
  }

  type t = {
    id: int,
    name: string,
    albums: array<albumWithSongs>,
  }
}

module Artists = {
  type columns = {
    id: Schema.Column.intColumn,
    name: Schema.Column.stringColumn,
  }

  type constraints = {pk: Schema.Constraint.t}

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
    id: Schema.Column.intColumn,
    artistId: Schema.Column.intColumn,
    name: Schema.Column.stringColumn,
    year: Schema.Column.intColumn,
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
    id: Schema.Column.intColumn,
    albumId: Schema.Column.intColumn,
    name: Schema.Column.stringColumn,
    duration: Schema.Column.stringColumn,
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
  type columns = {
    id: Schema.Column.intColumn,
    name: Schema.Column.stringColumn,
  }

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
  type columns = {
    songId: Schema.Column.intColumn,
    userId: Schema.Column.intColumn,
    likedAt: Schema.Column.dateColumn,
  }

  type constraints = {
    pk: Schema.Constraint.t,
    fkSong: Schema.Constraint.t,
    fkUser: Schema.Constraint.t,
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

module TestData = {
  let artists: array<Artist.t> = [
    {id: 1, name: "Architects"},
    {id: 2, name: "While She Sleeps"},
    {id: 3, name: "Misfits"},
    {id: 4, name: "Iron Maiden"},
    {id: 5, name: "UPDATEME"},
  ]

  let albums: array<Album.t> = [
    {id: 1, artist: artists[0]->Option.getUnsafe, name: "Hollow Crown", year: 2009},
    {id: 2, artist: artists[0]->Option.getUnsafe, name: "Lost Forever / Lost Together", year: 2014},
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
  ]

  let songs: array<Song.t> = [
    {id: 1, album: albums[0]->Option.getUnsafe, name: "Early Grave", duration: "3:32"},
    {id: 2, album: albums[0]->Option.getUnsafe, name: "Dethroned", duration: "3:06"},
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
  ]

  let users: array<User.t> = [{id: 1, name: "John Doe"}]

  let favorites: array<Favorite.t> = [
    {
      user: users[0]->Option.getUnsafe,
      song: songs[0]->Option.getUnsafe,
      likedAt: Date.fromString("2022-01-01"),
    },
  ]
}

let createTables = async () => {
  open QueryBuilder.CreateTable
  open QueryRunner.CreateTable

  let q1 = createTable(Artists.table)

  /* ->SQL.fromCreateTableQuery */
  let q2 = createTable(Albums.table)
  let q3 = createTable(Songs.table)
  let q4 = createTable(Users.table)
  let q5 = createTable(Favorites.table)

  q1->SQL.fromCreateTableQuery->log
  log("")

  q2->SQL.fromCreateTableQuery->log
  log("")

  q3->SQL.fromCreateTableQuery->log
  log("")

  q4->SQL.fromCreateTableQuery->log
  log("")

  q5->SQL.fromCreateTableQuery->log
  log("")

  let _ = execute(q1, exec)
  let _ = execute(q2, exec)
  let _ = execute(q3, exec)
  let _ = execute(q4, exec)
  let _ = execute(q5, exec)
}

let insertData = async () => {
  open QueryBuilder.Insert
  open QueryRunner.Insert

  let q1 =
    insertInto(Artists.table)
    ->values(
      Array.map(TestData.artists, artist => {
        Artists.id: literal(artist.id),
        name: literal(artist.name),
      }),
    )

  let q2 =
    insertInto(Albums.table)
    ->values(
      Array.map(TestData.albums, album => {
        Albums.id: literal(album.id),
        artistId: literal(album.artist.id),
        name: literal(album.name),
        year: literal(album.year),
      }),
    )

  let q3 =
    insertInto(Songs.table)
    ->values(
      Array.map(TestData.songs, song => {
        Songs.id: literal(song.id),
        albumId: literal(song.album.id),
        name: literal(song.name),
        duration: literal(song.duration),
      }),
    )

  let q4 =
    insertInto(Users.table)
    ->values(
      Array.map(TestData.users, user => {
        Users.id: literal(user.id),
        Users.name: literal(user.name),
      }),
    )

  let q5 =
    insertInto(Favorites.table)
    ->values(
      Array.map(TestData.favorites, favorite => {
        Favorites.userId: literal(favorite.user.id),
        songId: literal(favorite.song.id),
        likedAt: literal(favorite.likedAt),
      }),
    )

  
  q1->SQL.fromInsertQuery->log
  log("")

  q2->SQL.fromInsertQuery->log
  log("")

  q3->SQL.fromInsertQuery->log
  log("")

  q4->SQL.fromInsertQuery->log
  log("")

  q5->SQL.fromInsertQuery->log
  log("")

  let _ = await execute(q1, exec)
  let _ = await execute(q2, exec)
  let _ = await execute(q3, exec)
  let _ = await execute(q4, exec)
  let _ = await execute(q5, exec)
}

let updateData = async () => {
  open QueryBuilder.Update
  open QueryBuilder.Expr
  open QueryRunner.Update

  let q1 =
    update(Artists.table)
    ->set({
      id: skip,
      name: literal("DELETEME"),
    })
    ->where(c => equal(c.name, Literal("UPDATEME")))
    

  q1->SQL.fromUpdateQuery->log
  log("")

  let _ = await execute(q1, exec)
}

let deleteData = async () => {
  open QueryBuilder.Delete
  open QueryBuilder.Expr
  open QueryRunner.Delete

  let q1 =
    deleteFrom(Artists.table)->where(c => equal(c.name, Literal("DELETEME")))

  q1->SQL.fromDeleteQuery->log
  log("")

  let _ = await execute(q1, exec) 
}

let selectArtists = () => {
  open QueryBuilder.Select
  open QueryRunner.Select

  let q = from(Artists.table)->select(artist => {
    array({Artist.id: column(artist.id), name: column(artist.name)})
  })

  let sql = SQL.fromSelectQuery(q)

  log("")
  log(sql)
  log("")

  execute(q, getRows)->AsyncResult.tap(log)
}

let selectNameFromArtist1 = () => {
  open QueryBuilder.Select
  open QueryBuilder.Expr
  open QueryRunner.Select

  let q =
    from(Artists.table)
    ->where(artist => equal(artist.id, Literal(1)))
    ->select(artist => array({"name": column(artist.name)}))

  let sql = SQL.fromSelectQuery(q)

  log("")
  log(sql)
  log("")

  execute(q, getRows)->AsyncResult.tap(log)
}

let selectArtistsWithAlbumsWithSongsRaw = () => {
  open QueryBuilder.Select
  open QueryRunner.Select

  let q =
    from(Artists.table)
    ->leftJoin1(Albums.table, ((artist, album)) => (album.artistId, artist.id))
    ->leftJoin2(Songs.table, ((_artist, album, song)) => (song.albumId, Option.getUnsafe(album).id))
    ->select(((artist, album, song)) =>
      array({
        "artistName": column(artist.name),
        "albumName": optionalColumn(album, album => album.name),
        "songName": optionalColumn(song, song => song.name),
      })
    )

  let sql = SQL.fromSelectQuery(q)

  log("")
  log(sql)
  log("")

  execute(q, getRows)->AsyncResult.tap(log)
}

let selectArtistsWithAlbumsWithSongsNested = () => {
  open QueryBuilder.Select
  open QueryRunner.Select

  let q =
    from(Artists.table)
    ->leftJoin1(Albums.table, ((artist, album)) => (album.artistId, artist.id))
    ->leftJoin2(Songs.table, ((_artist, album, song)) => (song.albumId, Option.getUnsafe(album).id))
    ->select(((artist, album, song)) =>
      group(
        artist.id,
        {
          ArtistWithAlbumsWithSongs.id: column(artist.id),
          name: column(artist.name),
          albums: optionalGroup(
            album,
            album => album.id,
            album => {
              ArtistWithAlbumsWithSongs.id: column(album.id),
              name: column(album.name),
              year: column(album.year),
              songs: optionalGroup(
                song,
                song => song.id,
                song => {
                  ArtistWithAlbumsWithSongs.id: column(song.id),
                  name: column(song.name),
                  duration: column(song.duration),
                },
              ),
            },
          ),
        },
      )
    )

  let sql = SQL.fromSelectQuery(q)

  log("")
  log(sql)
  log("")

  execute(q, getRows)->AsyncResult.tap(log)
}

let selectFavoritesOfUser1 = () => {
  open QueryBuilder.Select
  open QueryRunner.Select

  let q =
    from(Favorites.table)
    ->innerJoin1(Songs.table, ((favorite, song)) => (favorite.songId, song.id))
    ->innerJoin2(Albums.table, ((_favorite, song, album)) => (song.albumId, album.id))
    ->innerJoin3(Artists.table, ((_favorite, _song, album, artist)) => (album.artistId, artist.id))
    ->select(((favorite, song, album, artist)) =>
      array({
        "songName": column(song.name),
        "albumName": column(album.name),
        "artistName": column(artist.name),
        "likedAt": column(favorite.likedAt),
      })
    )

  let sql = SQL.fromSelectQuery(q)

  log("")
  log(sql)
  log("")

  execute(q, getRows)->AsyncResult.tap(log)
}

let expressionsTest = () => {
  open QueryBuilder.Select
  open QueryBuilder.Expr

  let expressions = [
    (c: Artists.columns) => equal(c.id, Literal(1)),
    (c: Artists.columns) => notEqual(c.id, Literal(1)),
    (c: Artists.columns) => greaterThan(c.id, Literal(1)),
    (c: Artists.columns) => greaterThanEqual(c.id, Literal(1)),
    (c: Artists.columns) => lessThan(c.id, Literal(1)),
    (c: Artists.columns) => lessThanEqual(c.id, Literal(1)),
    (c: Artists.columns) => between(c.id, Literal(1), Literal(2)),
    (c: Artists.columns) => notBetween(c.id, Literal(1), Literal(2)),
    (c: Artists.columns) => in_(c.id, [Literal(1), Literal(2)]),
    (c: Artists.columns) => notIn(c.id, [Literal(1), Literal(2)]),
    (c: Artists.columns) => and_([equal(c.id, Literal(1)), notEqual(c.name, Literal("test"))]),
    (c: Artists.columns) => or([equal(c.id, Literal(1)), notEqual(c.name, Literal("test"))]),
  ]

  expressions->Js.Array2.forEach(expression => {
    from(Artists.table)
    ->where(expression)
    ->select(c => array({"id": column(c.id)}))
    ->SQL.fromSelectQuery
    ->Js.log

    Js.log("")
  })
}

let limitAndOffsetTest = () => {
  open QueryBuilder.Select

  from(Artists.table)
  ->limit(10)
  ->offset(5)
  ->select(c => array({"id": column(c.id)}))
  ->SQL.fromSelectQuery
  ->Js.log

  Js.log("")
}

let orderByTest = () => {
  open QueryBuilder.Select

  from(Artists.table)
  ->addOrderBy(c => c.id, Asc)
  ->addOrderBy(c => c.name, Desc)
  ->select(c => array({"id": column(c.id)}))
  ->SQL.fromSelectQuery
  ->Js.log

  Js.log("")
}

let groupByTest = () => {
  open QueryBuilder.Select
  open QueryBuilder.Expr

  from(Artists.table)
  ->addGroupBy(c => c.id)
  ->addGroupBy(c => c.name)
  ->having(c => equal(c.id, Literal(1)))
  ->select(c => array({"id": column(c.id)}))
  ->SQL.fromSelectQuery
  ->Js.log

  Js.log("")
}

/* let subQueryTest = () => { */
/* open QueryBuilder.Select */
/* open QueryBuilder.Expr */
/* open SubQueryBuilder */

/* from(Artists.table) */
/* ->where(c => equal(c.id, from(Artists.table)->make(c => Agg.max(c.id)))) */
/* ->select(c => array({"id": column(c.id)})) */
/* ->SQL.fromSelectQuery */
/* ->Js.log */

/* Js.log("") */
/* } */

let aggregationTest = () => {
  open QueryBuilder.Select

  let q = from(Artists.table)->select(c =>
    array({
      "count": Agg.count(c.name),
      "sum": Agg.sum(c.name),
      "avg": Agg.avg(c.name),
      "min": Agg.min(c.name),
      "max": Agg.max(c.name),
    })
  )

  let sql = SQL.fromSelectQuery(q)

  log(sql)
  log("")
}

let test = async () => {
  let _ = await createTables()
  let _ = await insertData()
  let _ = await updateData()
  let _ = await deleteData()
  let _ = await selectArtists()
  let _ = await selectNameFromArtist1()
  let _ = await selectArtistsWithAlbumsWithSongsRaw()
  let _ = await selectArtistsWithAlbumsWithSongsNested()
  let _ = await selectFavoritesOfUser1()
  expressionsTest()
  limitAndOffsetTest()
  orderByTest()
  groupByTest()
  /* subQueryTest() */
  aggregationTest()
}

let _ = test()
