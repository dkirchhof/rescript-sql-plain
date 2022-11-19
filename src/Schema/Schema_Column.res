type t = {
  table: string,
  name: string,
  dbType: [#VARCHAR | #INTEGER],
  size: int,
}

external toColumnUnsafe: 'a => t = "%identity"

type options = {size: int}

let varchar = (options): string => {
  {table: "", name: "", dbType: #VARCHAR, size: options.size}->Obj.magic
}

let integer = (options): int => {
  {table: "", name: "", dbType: #INTEGER, size: options.size}->Obj.magic
}
