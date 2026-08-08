import gleamtea.{type Cmd, type Event, Key, None, Quit, Resize, User}
import gleamtea/key.{Char}

import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import shared.{type Input, Input, Robot, parse, unwrap}

type Model {
  Model(input: Input, time: Int, has_line: Bool)
}

fn new_model(input: Input, time: Int) -> Model {
  Model(input: input, time: time, has_line: has_line(input))
}

fn show(input: Model) -> String {
  let Model(input, time, has_line) = input
  let Input(w, h, bots) = input

  let bots =
    bots
    |> list.fold(from: dict.new(), with: fn(d, bot) {
      dict.upsert(d, #(bot.x, bot.y), fn(val) { option.unwrap(val, 0) + 1 })
    })

  let header = string.repeat("#", w + 2)

  int.range(from: 0, to: h, with: header, run: fn(acc, y) {
    let line: String =
      int.range(from: 0, to: w, with: "#", run: fn(line_acc, x) {
        line_acc
        <> case dict.get(bots, #(x, y)) {
          Ok(num) ->
            case num {
              x if x <= 0 -> panic as { "Invalid count: " <> int.to_string(x) }
              x if x < 10 -> int.to_string(x)
              _ -> "*"
            }
          Error(_) -> " "
        }
      })
      <> "#"

    acc <> "\n" <> line
  })
  <> {
    "\n"
    <> header
    <> "\n"
    <> "time: "
    <> int.to_string(time)
    <> " has_line: "
    <> bool.to_string(has_line)
  }
}

fn init(input: Input) -> fn() -> #(Model, Cmd(Event(Nil))) {
  fn() { #(new_model(input, 0), None) }
}

fn step_model(model: Model, step: Int) -> Model {
  let Model(input, time, _) = model
  let Input(w, h, bots) = input

  let moved_bots =
    bots
    |> list.map(fn(bot) {
      let Robot(x, y, vx, vy) = shared.step(bot, step)
      let x = int.modulo(x, w) |> unwrap
      let y = int.modulo(y, h) |> unwrap
      Robot(x, y, vx, vy)
    })

  let input = Input(w, h, moved_bots)
  new_model(input, time + step)
}

fn has_line(model: Input) -> Bool {
  let by_x = list.group(model.robots, fn(bot) { bot.x })
  let tallest_line =
    by_x
    |> dict.values
    |> list.map(fn(bots) {
      bots
      |> list.map(fn(bot) { bot.y })
      |> list.unique
      |> list.sort(int.compare)
      |> list.scan(#(0, 0), fn(acc, y) {
        let #(run, last) = acc
        case run {
          0 -> #(1, y)
          _ -> {
            case last + 1 == y {
              True -> #(run + 1, y)
              False -> #(1, y)
            }
          }
        }
      })
      |> list.map(fn(acc) { acc.0 })
      |> list.max(int.compare)
      |> unwrap
    })
    |> list.max(int.compare)
    |> unwrap

  tallest_line >= 10
}

fn step_until_line(model: Model, step: Int, max_steps: Int) -> Model {
  case max_steps {
    0 -> model
    _ -> {
      let model = step_model(model, step)
      case model.has_line {
        True -> model
        False -> step_until_line(model, step, max_steps - 1)
      }
    }
  }
}

fn update(msg: Event(Nil), model: Model) -> #(Model, Cmd(Event(Nil))) {
  case msg {
    Key(k) ->
      case k {
        // q
        Char(113) -> #(model, Quit)

        // l
        Char(108) -> #(step_model(model, 1), None)
        // h
        Char(104) -> #(step_model(model, -1), None)

        // k
        Char(107) -> #(step_until_line(model, 1, 10_000), None)
        // j
        Char(106) -> #(step_until_line(model, -1, 10_000), None)

        _ -> #(model, None)
      }
    Resize(_) -> #(model, None)
    User(_) -> #(model, None)
  }
}

pub fn sim(input: String) -> Nil {
  let res =
    gleamtea.program(init: init(input |> parse), update:, view: show)
    |> gleamtea.start

  case res {
    Ok(_) -> Nil
    Error(err) -> io.println_error(string.inspect(err))
  }
}
