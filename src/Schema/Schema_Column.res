type t = {
  table: string,
  name: string,
  dbType: [#VARCHAR | #INTEGER | #TEXT],
  size: option<int>,
}

external toColumnUnsafe: 'a => t = "%identity"

type options = {size?: int}

let varchar = (options): string => {
  {table: "", name: "", dbType: #VARCHAR, size: options.size}->Obj.magic
}

let text = (options): string => {
  {table: "", name: "", dbType: #TEXT, size: options.size}->Obj.magic
}

let integer = (options): int => {
  {table: "", name: "", dbType: #INTEGER, size: options.size}->Obj.magic
}
