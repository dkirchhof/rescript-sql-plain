type t<'a, 'b> = {
  table: string,
  name: string,
  dbType: [#VARCHAR | #INTEGER | #TEXT],
  size: option<int>,
  converter: option<'a => 'b>,
}

type options = {size?: int}

let varchar = (options): string =>
  {table: "", name: "", dbType: #VARCHAR, size: options.size, converter: None}->Obj.magic

let text = (options): string =>
  {table: "", name: "", dbType: #TEXT, size: options.size, converter: None}->Obj.magic

let integer = (options): int =>
  {table: "", name: "", dbType: #INTEGER, size: options.size, converter: None}->Obj.magic

let date = (options): Js.Date.t =>
  {
    {
      table: "",
      name: "",
      dbType: #INTEGER,
      size: options.size,
      converter: Some(Js.Date.fromString),
    }
  }->Obj.magic
