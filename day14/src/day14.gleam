import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

import shared.{type Robot, Input, Robot, parse, step, to_int, unwrap}
import sim

fn quadrant(bot: Robot, w: Int, h: Int) -> Result(Int, Nil) {
  let Robot(x, y, _, _) = bot

  let x = { int.modulo(x, w) |> unwrap } - w / 2
  let y = { int.modulo(y, h) |> unwrap } - h / 2

  case x == 0 || y == 0 {
    True -> Error(Nil)
    False -> {
      let qx = to_int(x > 0)
      let qy = to_int(y > 0)
      Ok(qx + qy * 2)
    }
  }
}

fn inc(l: List(Int), idx: Int) -> List(Int) {
  list.index_map(l, fn(count, i) {
    case i == idx {
      True -> count + 1
      False -> count
    }
  })
}

pub fn part1(input: String) -> Int {
  let Input(w, h, bots) = parse(input)

  bots
  |> list.map(fn(bot) { step(bot, 100) })
  |> list.filter_map(fn(bot) { quadrant(bot, w, h) })
  |> list.fold([0, 0, 0, 0], fn(acc, q) { inc(acc, q) })
  |> int.product
}

fn load_input(infile: String) -> String {
  simplifile.read(infile)
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  let argv = argv.load()
  case argv.arguments {
    [] -> {
      let input = load_input("input.txt")
      io.println("Part 1: " <> string.inspect(part1(input)))
      io.println(
        "Part 2: " <> "`gleam run sim large` -> k until you find a tree",
      )
    }
    ["sim", ..rest] -> {
      let size = case rest {
        [] -> panic as { "Missing simulation size" }
        [size] -> size
        [_, ..rest] ->
          panic as { "Extra simulation args: " <> string.inspect(rest) }
      }

      let input =
        load_input(case size {
          "small" -> "small-in.txt"
          "large" -> "input.txt"
          _ -> panic as { "Invalid simulation size: " <> size }
        })

      sim.sim(input)
    }
    _ -> panic as { "Invalid args: " <> string.inspect(argv.arguments) }
  }
}
