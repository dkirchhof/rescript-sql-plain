type rec t<'a> =
  | And(array<t<'a>>)
  | Or(array<t<'a>>)
  | Equal('a, 'a)
  | NotEqual('a, 'a)
  | GreaterThan('a, 'a)
  | GreaterThanEqual('a, 'a)
  | LessThan('a, 'a)
  | LessThanEqual('a, 'a)
  | Between('a, 'a, 'a)
  | NotBetween('a, 'a, 'a)
  | In('a, array<'a>)
  | NotIn('a, array<'a>)

%%private(
  let and_ = expressions => expressions->Obj.magic->And
  let or_ = expressions => expressions->Obj.magic->Or
)

let and2: ((t<_>, t<_>)) => t<_> = and_
let and3: ((t<_>, t<_>, t<_>)) => t<_> = and_
let and4: ((t<_>, t<_>, t<_>, t<_>)) => t<_> = and_
let and5: ((t<_>, t<_>, t<_>, t<_>, t<_>)) => t<_> = and_
let or2: ((t<_>, t<_>)) => t<_> = or_
let or3: ((t<_>, t<_>, t<_>)) => t<_> = or_
let or4: ((t<_>, t<_>, t<_>, t<_>)) => t<_> = or_
let or5: ((t<_>, t<_>, t<_>, t<_>, t<_>)) => t<_> = or_
