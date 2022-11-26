open QueryBuilder.Select

let make = (q: t<'columns>, getColumn: 'columns => Node.t<'t, _>): Node.t<'t, _> => {
  let column = Utils.ItemOrArray.apply(q.columns, getColumn)

  q->select(_ => {"_": column})->SQL.fromSelectQuery->Obj.magic->Node.Query
}
