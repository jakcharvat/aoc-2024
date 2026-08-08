import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn unwrap(result: Result(ok, err)) -> ok {
  result.lazy_unwrap(result, fn() { panic })
}

pub fn to_int(b: Bool) -> Int {
  case b {
    True -> 1
    False -> 0
  }
}

pub type Robot {
  Robot(x: Int, y: Int, vx: Int, vy: Int)
}

pub type Input {
  Input(w: Int, h: Int, robots: List(Robot))
}

pub fn parse_int(s: String) -> Int {
  int.parse(s) |> unwrap
}

pub fn parse(input: String) -> Input {
  let assert [size, ..robots] =
    input
    |> string.trim
    |> string.split("\n")

  let assert [w, h] =
    size
    |> string.trim
    |> string.split(",")
    |> list.map(parse_int)

  let bots =
    robots
    |> list.map(fn(s) {
      let assert [p, v] = string.split(s, " ")
      let parse_xy = fn(s: String) {
        let assert [_, nums] = string.split(s, "=")
        let assert [x, y] =
          string.split(nums, ",")
          |> list.map(parse_int)
        #(x, y)
      }

      let #(x, y) = parse_xy(p)
      let #(vx, vy) = parse_xy(v)
      Robot(x, y, vx, vy)
    })

  Input(w, h, bots)
}

pub fn step(bot: Robot, steps: Int) -> Robot {
  let Robot(x, y, vx, vy) = bot
  Robot(x + vx * steps, y + vy * steps, vx, vy)
}
