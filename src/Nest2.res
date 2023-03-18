%%raw(`
  import { inspect } from "util";
`)

let log: 'a => unit = %raw(`
  function log(message) {
    console.log(inspect(message, false, 10, true));
  }
`)

type itemOrArray<'a> = Item('a) | Array(array<'a>)

type metaValueProps = {
  prop: string,
  column: itemOrArray<string>,
}

type metaColumnData<'a> = {
  valueList: array<metaValueProps>,
  toOneList: array<metaValueProps>,
  arraysList: array<metaValueProps>,
  toManyPropList: array<string>,
  containingColumn: option<array<string>>,
  ownProp: option<string>,
  isOneOfMany: bool,
  cache: Dict.t<'a>,
  containingIdUsage: option<Dict.t<Dict.t<bool>>>,
}

type metaData<'a> = {
  primeIdColumnList: array<array<string>>,
  idMap: Dict.t<metaColumnData<'a>>,
}

type definitionColumn = {
  column: string,
  id: bool,
}

type rec node =
  ColumnDefinition(definitionColumn) | ArrayDefinition(array<node>) | ObjectDefinition(Dict.t<node>)

let rows = [
  {
    "artist_id": 1,
    "artist_name": "artist 1",
    "genre_id": 1,
    "genre_name": "genre 1",
    "song_id": 1,
    "song_name": "song 1",
  },
  {
    "artist_id": 1,
    "artist_name": "artist 1",
    "genre_id": 1,
    "genre_name": "genre 1",
    "song_id": 2,
    "song_name": "song 2",
  },
  {
    "artist_id": 2,
    "artist_name": "artist 2",
    "genre_id": 1,
    "genre_name": "genre 1",
    "song_id": 3,
    "song_name": "song 3",
  },
]

let def = ArrayDefinition([
  ObjectDefinition(
    {
      "id": ColumnDefinition({column: "artist_id", id: true}),
      "name": ColumnDefinition({column: "artist_name", id: false}),
      "genre": ObjectDefinition(
        {
          "id": ColumnDefinition({column: "genre_id", id: true}),
          "name": ColumnDefinition({column: "genre_name", id: false}),
        }->Obj.magic,
      ),
      "songs": ArrayDefinition([
        ObjectDefinition(
          {
            "id": ColumnDefinition({column: "song_id", id: true}),
            "name": ColumnDefinition({column: "song_name", id: false}),
          }->Obj.magic,
        ),
      ]),
    }->Obj.magic,
  ),
])

// get artists by artist_id (withValuesGetter, with genreGetter, with songsGetter)
// get songs by song_id
// get genres by genre_id?

let createCompositeKey = vals => {
  Array.joinWith(vals, ", ")
}

let buildMeta = def => {
  let meta = {
    primeIdColumnList: [],
    idMap: Dict.make(),
  }

  let rec recursiveBuildMeta = (def, isOneOfMany, containingColumn, ownProp) => {
    let idProps = []
    let idColumns = []

    switch def {
    | ObjectDefinition(def) => {
        let entries = Dict.toArray(def)

        if Array.length(entries) === 0 {
          panic("def is empty")
        }
        // if entries.length === 0 ? error

        Array.forEach(entries, ((key, value)) => {
          switch value {
          | ColumnDefinition(def) =>
            if def.id === true {
              Array.push(idProps, key)
              Array.push(idColumns, def.column)
            }
          | _ => ()
          }
        })

        if isOneOfMany {
          Array.push(meta.primeIdColumnList, idColumns)
        }

        let objMeta: metaColumnData<_> = {
          valueList: [],
          toOneList: [],
          arraysList: [],
          toManyPropList: [],
          containingColumn,
          ownProp,
          isOneOfMany: isOneOfMany === true,
          cache: Dict.make(),
          containingIdUsage: Option.isNone(containingColumn) ? None : Dict.make()->Some,
        }

        Array.forEach(entries, ((key, value)) => {
          switch value {
          | ColumnDefinition(def) => {
              let metaValueProps = {
                prop: key,
                column: Item(def.column),
              }

              Array.push(objMeta.valueList, metaValueProps)
            }

          | ArrayDefinition(defs) => {
              Array.push(objMeta.toManyPropList, key)

              recursiveBuildMeta(defs[0]->Option.getExn, true, Some(idColumns), Some(key))
            }

          | ObjectDefinition(def) => {
              let subIdProps = []

              Dict.valuesToArray(def)->Array.forEach(subDef => {
                switch subDef {
                | ColumnDefinition(columnDef) =>
                  if columnDef.id === true {
                    Array.push(subIdProps, columnDef.column)
                  }
                | _ => ()
                }
              })

              Array.push(
                objMeta.toOneList,
                {
                  prop: key,
                  column: Array(subIdProps),
                },
              )

              recursiveBuildMeta(value, false, Some(idColumns), Some(key))
            }
          }
        })
        Dict.set(meta.idMap, createCompositeKey(idColumns), objMeta)
      }

    | _ => ()
    }

    /* Console.log(idProps) */
    /* Console.log(idColumns) */
  }

  switch def {
  | ArrayDefinition([first]) => recursiveBuildMeta(first, true, None, None)
  | _ => panic("only single item in array allowed")
  }

  meta
}

let struct: array<string> = []

let nest = (rows, def) => {
  // todo: check if rows is an array, obj or null

  let meta = buildMeta(def)
log(meta)
  let rec recursiveNest = (row, idColumns) => {
    let row = Obj.magic(row)
    /* let obj = Dict.make() */

    let idVals = Array.map(idColumns, column => Dict.get(row, column))
    let objMeta = Dict.get(meta.idMap, createCompositeKey(idColumns))->Option.getExn;

    switch Dict.get(objMeta.cache, createCompositeKey(idVals)) {
      | Some(cached) => {
        Array.forEach(objMeta.arraysList, prop => {
          // todo: remove obj.magic
          let cellValue = Dict.get(row, Obj.magic(prop).column)
        
          Console.log2(cached, cellValue)
        })
        
      }
      | None => ()
    }

				/* if (typeof objMeta.cache[createCompositeKey(vals)] !== 'undefined') { */

				/* 	// not already placed as to-many relation in container */
				/* 	obj = objMeta.cache[createCompositeKey(vals)]; */

				/* 	// Add array values if necessary */
				/* 	for (const prop of objMeta.arraysList) { */
				/* 		const cellValue = this.computeActualCellValue(prop, row[prop.column as string]); */
				/* 		if (isArray(obj[prop.prop])) { */
				/* 			obj[prop.prop].push(cellValue); */
				/* 		} else { */
				/* 			obj[prop.prop] = [cellValue]; */
				/* 		} */
				/* 	} */

				/* 	if (objMeta.containingIdUsage === null) { return; } */

				/* 	// We know for certain that containing column is set if */
				/* 	// containingIdUsage is not null and can cast it as a string */

				/* 	// check and see if this has already been linked to the parent, */
				/* 	// and if so we don't need to continue */
				/* 	const containingIds = (objMeta.containingColumn as string[]).map((column) => row[column]); */
				/* 	if (typeof objMeta.containingIdUsage[createCompositeKey(vals)] !== 'undefined' */
				/* 		&& typeof objMeta.containingIdUsage[createCompositeKey(vals)][createCompositeKey(containingIds)] !== 'undefined' */
				/* 	) { return; } */

				/* } else { */
				/* 	// don't have an object defined for this yet, create it and set the cache */
				/* 	obj = {}; */
				/* 	objMeta.cache[createCompositeKey(vals)] = obj; */

				/* 	// copy in properties from table data */
				/* 	for (const prop of objMeta.valueList) { */
				/* 		const cellValue = this.computeActualCellValue(prop, row[prop.column as string]); */
				/* 		obj[prop.prop] = cellValue; */
				/* 	} */

				/* 	// Add array values */
				/* 	for (const prop of objMeta.arraysList) { */
				/* 		const cellValue = this.computeActualCellValue(prop, row[prop.column as string]); */
				/* 		if (isArray(obj[prop.prop])) { */
				/* 			obj[prop.prop].push(cellValue); */
				/* 		} else { */
				/* 			obj[prop.prop] = [cellValue]; */
				/* 		} */
				/* 	} */

				/* 	// initialize empty to-many relations, they will be populated when */
				/* 	// those objects build themselves and find this containing object */
				/* 	for (const prop of objMeta.toManyPropList) { */
				/* 		obj[prop] = []; */
				/* 	} */

				/* 	// initialize null to-one relations and then recursively build them */
				/* 	for (const prop of objMeta.toOneList) { */
				/* 		obj[prop.prop] = null; */
				/* 		recursiveNest(row, Array.isArray(prop.column) ? prop.column : [prop.column]); */
				/* 	} */
				/* } */
  }

  Array.forEach(rows, row => {
    Array.forEach(meta.primeIdColumnList, primeIdColumn => {
      recursiveNest(row, primeIdColumn)
    })
  })

  struct
}

/* buildMeta(def)->log */
nest(rows, def)->log

/* let groups = [ */

/* ] */

/* let r = [ */
/* ( */
/* 1, */
/* [ */
/* {"artist_id": 1, "artist_name": "artist 1", "song_id": 1, "song_name": "song 1"}, */
/* {"artist_id": 1, "artist_name": "artist 1", "song_id": 2, "song_name": "song 2"}, */
/* ], */
/* ), */
/* (2, [{"artist_id": 2, "artist_name": "artist 2", "song_id": 3, "song_name": "song 3"}]), */
/* ] */

/* let r = [ */
/* ( */
/* 1, */
/* [ */
/* { */
/* "artist_id": 1, */
/* "artist_name": "artist 1", */
/* "song_id": 1, */
/* "song_name": "song 1", */
/* "songs": [ */
/* (1, [{"artist_id": 1, "artist_name": "artist 1", "song_id": 2, "song_name": "song 2"}]), */
/* ], */
/* }, */
/* ], */
/* ), */
/* (2, [{"artist_id": 2, "artist_name": "artist 2", "song_id": 3, "song_name": "song 3"}]), */
/* ] */

/* let r = [ */
/* { */
/* "id": 1, */
/* "name": "artist 1", */
/* "songs": [{"id": 1, "name": "song 1"}, {"id": 2, "name": "song 2"}], */
/* }, */
/* { */
/* "id": 2, */
/* "name": "artist 2", */
/* "songs": [{"id": 3, "name": "song 3"}], */
/* }, */
/* ] */

/* type schema<'a, 'b> = Value('b) | Group('a, 'b) | Array('a, 'b) */

/* let obj = (id: 'a, objSchema: 'b): 'b => { */
/* Group(id, objSchema)->Obj.magic */
/* } */

/* let array = (id: 'a, itemsSchema: 'b): array<'b> => { */
/* Array(id, itemsSchema)->Obj.magic */
/* } */

/* let test1 = () => { */
/* let obj = row => ( */
/* row["artist_id"], */
/* { */
/* "id": row["artist_id"], */
/* "name": row["artist_name"], */
/* "song": {"id": row["song_name"], "name": row["song_name"]}, */
/* }, */
/* ) */

/* let result = Map.make() */

/* rows->Array.forEach(row => { */
/* let (id, schema) = obj(row) */

/* switch Map.get(result, id) { */
/* | Some(_) => () */
/* | None => Map.set(result, id, schema) */
/* } */
/* }) */

/* Console.log(result) */
/* } */

/* let test2 = () => { */
/* let schema = row => */
/* obj( */
/* row["artist_id"], */
/* { */
/* "id": row["artist_id"], */
/* "name": row["artist_name"], */
/* "genre": {"id": row["genre_id"], "name": row["genre_name"]}, */
/* "songs": array(row["song_id"], {"id": row["song_id"], "name": row["song_name"]}), */
/* }, */
/* ) */

/* let result = Map.make() */

/* rows->Array.forEach(row => { */
/* let rowSchema = schema(row)->Obj.magic */

/* let Group(id, objSchema) = rowSchema */

/* let obj = Dict.make() */

/* objSchema */
/* ->Obj.magic */
/* ->Dict.toArray */
/* ->Array.forEach(((key, value)) => { */
/* switch value { */
/* | Array(id, itemsSchema) => () */
/* | Group(id, objSchema) => () */
/* | Value(_) => Dict.set(obj, key, value) */
/* } */
/* }) */

/* // if obj */
/* switch Map.get(result, id) { */
/* | Some(items) => () // Array.push(items, obj) */
/* | None => Map.set(result, id, obj) */
/* } */
/* }) */

/* Console.log(result) */
/* } */

/* /1* test1() *1/ */
/* /1* test2() *1/ */
