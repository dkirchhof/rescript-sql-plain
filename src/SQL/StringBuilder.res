type t = array<string>

let make = () => []

let addS = (builder, indentation, line) => {
  let spaces = Js.String2.repeat(" ", indentation)

  Js.Array2.push(builder, spaces ++ line)->ignore

  builder
}

let addSO = (builder, indentation, optionalLine) => {
  switch optionalLine {
  | Some(line) => addS(builder, indentation, line)->ignore
  | None => ignore()
  }

  builder
}

let addM = (builder, indentation, lines) => {
  lines->Js.Array2.forEach(line => addS(builder, indentation, line)->ignore)

  builder
}

let addMO = (builder, indentation, optionalLines) => {
  switch optionalLines {
  | Some(lines) => addM(builder, indentation, lines)->ignore
  | None => ignore()
  }

  builder
}

let addE = builder => {
  Js.Array2.push(builder, "")->ignore

  builder
}

let build = Js.Array2.joinWith
