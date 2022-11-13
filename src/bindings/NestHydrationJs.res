type t

@module("nesthydrationjs") external make: () => t = "default"

@send external nestOne: (t, {..}, 'result) => 'result = "nest"
@send external nestMany: (t, array<{..}>, array<'result>) => array<'result> = "nest"
