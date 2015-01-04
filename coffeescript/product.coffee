Many = (vs) ->
  bind: (f) -> Many (f(v).values for v in vs).reduce (a, b) -> a.concat b
  values: vs
Many.unit = (v) -> Many [v]

xs = [1, 2, 3]
ys = [4, 5]

r = Many(xs).bind (x) ->
      Many(ys).bind (y) ->
        Many.unit [x, y]

console.log r.values
