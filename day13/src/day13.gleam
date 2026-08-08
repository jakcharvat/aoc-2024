import atto
import atto/ops
import atto/text
import atto/text_util
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Button {
  Button(x: Int, y: Int)
}

fn div_button(num: Button, den: Button) -> Result(Int, Nil) {
  case den.x {
    0 -> {
      use <- bool.guard(num.x != 0 && num.y % den.y == 0, Error(Nil))
      Ok(num.y / den.y)
    }
    x -> {
      use <- bool.guard(num.x % x != 0, Error(Nil))
      let qx = num.x / x
      use <- bool.guard(num.y != den.y * qx, Error(Nil))
      Ok(qx)
    }
  }
}

type Arcade {
  Arcade(a: Button, b: Button, target_x: Int, target_y: Int)
}

fn parse_button(button: String) {
  use <- atto.label("button")
  use <- atto.drop(text.match("Button " <> button <> ": X\\+"))
  use x <- atto.do(text_util.decimal())
  use <- atto.drop(text.match(", Y\\+"))
  use y <- atto.do(text_util.decimal() |> text_util.ws)

  atto.pure(Button(x, y))
}

fn parse_arcade(part2: Bool) {
  use <- atto.label("arcade")
  use a <- atto.do(parse_button("A"))
  use b <- atto.do(parse_button("B"))
  use <- atto.drop(text.match("Prize: X="))
  use x <- atto.do(text_util.decimal())
  use <- atto.drop(text.match(", Y="))
  use y <- atto.do(text_util.decimal() |> text_util.ws)

  let add = case part2 {
    True -> 10_000_000_000_000
    False -> 0
  }

  atto.pure(Arcade(a, b, x + add, y + add))
}

fn parse(s: String, p: atto.Parser(a, String, String, Nil, c)) {
  atto.run(p, text.new(s), Nil)
}

fn grab(arcade: Arcade) -> Result(Int, Nil) {
  list.range(0, 100)
  |> list.filter_map(fn(a) {
    let a_pos = Button(arcade.a.x * a, arcade.a.y * a)
    let rem = Button(arcade.target_x - a_pos.x, arcade.target_y - a_pos.y)
    use b <- result.try(div_button(rem, arcade.b))

    Ok(a * 3 + b)
  })
  |> list.sort(by: int.compare)
  |> list.first
}

pub fn part1(input: String) -> Int {
  input
  |> parse(parse_arcade(False) |> ops.many)
  |> result.lazy_unwrap(fn() { panic })
  |> list.filter_map(grab)
  |> int.sum
}

fn hard_div(a: Int, b: Int) -> Result(Int, Nil) {
  case a % b {
    0 -> Ok(a / b)
    _ -> Error(Nil)
  }
}

fn grab2(arcade: Arcade) -> Result(Int, Nil) {
  let Arcade(a, b, x, y) = arcade
  let d = b.x * a.y - a.x * b.y
  let k = a.y * x - a.x * y

  assert d != 0 as "Lin. dependent EEA solution not implemented"

  use num_b <- result.try(hard_div(k, d))
  use num_a <- result.try(hard_div(a.y * x - b.x * a.y * num_b, a.x * a.y))

  assert num_a > 0 && num_b > 0
  Ok(num_a * 3 + num_b)
}

pub fn part2(input: String) -> Int {
  let buttons =
    input
    |> parse(parse_arcade(True) |> ops.many)
    |> result.lazy_unwrap(fn() { panic })

  buttons
  |> list.filter_map(grab2)
  |> int.sum
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
