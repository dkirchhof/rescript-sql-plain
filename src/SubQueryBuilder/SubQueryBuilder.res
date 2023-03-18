open QueryBuilder.Select

let make = (q: t<'columns, _>, getColumn: 'columns => 't): Node.t<'t, _> => {
  let column = Utils.ItemOrArray.apply(q.columns, getColumn)

  q->select(_ => {"_": column})->SQL.fromSelectQuery->Obj.magic->Node.Query
}
