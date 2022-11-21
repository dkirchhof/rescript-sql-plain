/*let eq = (column: column<'res, _>, value: 'res) => { */
/*  switch column.converter { */
/*  | Some(converter) => converter.resToDB(value)->Js.log */
/*  | None => value->Js.log */
/*  } */
/*} */

/*let row = { */
/*  "id": 1, */
/*  "birthdate": "2022-01-01", */
/*} */

/*type columnOrLiteral<'res, 'db> = Column(column<'res, 'db>) | Literal('res) */

/*type projection<'res, 'db> = {alias: string, columnOrLiteral: columnOrLiteral<'res, 'db>} */

/*let selectColumn = (column: column<'res, _>): 'res => Column(column)->Obj.magic */
/*let selectLiteral = (value: 'res): 'res => Literal(value)->Obj.magic */

/*let select = (columns: 'projection): 'projection => { */
/*  /1* let counter = ref(0) *1/ */ 

/*  /1* Js.Dict.map((. columnOrLiteral) => { *1/ */
/*  /1*   counter.contents = counter.contents + 1 *1/ */

/*  /1*   (counter.contents, columnOrLiteral) *1/ */
/*  /1* }, columns->Obj.magic)->Obj.magic *1/ */

/*  columns */
/*} */

/*let map = (definition, row) => { */
/*  /1* Js.Dict.map((. columnOrLiteral) => { *1/ */
/*  /1*   switch columnOrLiteral { *1/ */
/*  /1*   | Column(column) => { *1/ */
/*  /1*       let value = row->Obj.magic->Js.Dict.unsafeGet(column.name) *1/ */

/*  /1*       switch column.converter { *1/ */
/*  /1*       | Some(converter) => converter.dbToRes(value) *1/ */
/*  /1*       | None => value *1/ */
/*  /1*       } *1/ */
/*  /1*     } *1/ */

/*  /1*   | Literal(value) => value *1/ */
/*  /1*   } *1/ */
/*  /1* }, definition->Obj.magic)->Obj.magic *1/ */
/*  "" */
/*} */

/*let projection = select({ */
/*  "id": selectColumn(Users.table.columns.id), */
/*  "birthdate": selectColumn(Users.table.columns.birthdate), */
/*  "test": selectLiteral(1), */
/*  "sub": { */
/*    "id": selectColumn(Users.table.columns.id), */
/*  }, */
/*}) */

/*/1* */ 
/*  id: users.id as "id" */
/*  birthdate: users.birthdate as "birthdate" */
/*  test: 1 as "1" */
/*  sub.id: users.id as "sub.id" */

/*Js.log(projection) */
/*map(projection, row)->Js.log */
