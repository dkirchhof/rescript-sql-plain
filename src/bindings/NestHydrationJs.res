type t

@module("nesthydrationjs") external make: () => t = "default"

@send external nestOne: (t, {..}, {..} as 'result) => 'result = "nest"
@send external nestMany: (t, array<{..}>, array<{..} as 'result>) => 'result = "nest"
