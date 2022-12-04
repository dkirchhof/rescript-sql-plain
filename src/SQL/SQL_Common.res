let getNonSkippedColumns = (~record, ~columns) => {
  record
  ->Node.dictFromRecord
  ->Js.Dict.entries
  ->Js.Array2.filter(((_, value)) => value !== Node.Skip)
  ->Js.Array2.map(((columnName, _)) =>
    columns->Schema.Column.dictFromRecord->Js.Dict.unsafeGet(columnName)
  )
}

let convertIfNeccessary = (value, targetColumn: Schema_Column.t<_>) => {
  switch targetColumn.converter {
  | Some(converter) => value->converter.resToDB
  | _ => value
  }
}

let convertRecordToStringDict = (~record, ~columns: array<Schema_Column.t<_>>) => {
  columns
  ->Js.Array2.map(column => {
    let value = record->Node.dictFromRecord->Js.Dict.unsafeGet(column.name)

    let valueString = switch value {
    | Node.Literal(value) => convertIfNeccessary(value, column)->Utils.stringify
    | _ => Js.Exn.raiseError("not implemented yet")
    }

    (column.name, valueString)
  })
  ->Js.Dict.fromArray
}
