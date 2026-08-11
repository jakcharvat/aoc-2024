import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import simplifile

fn mix(secret: Int, value: Int) -> Int {
  int.bitwise_exclusive_or(secret, value)
}

fn prune(secret: Int) -> Int {
  int.bitwise_and(secret, 16_777_216 - 1)
}

fn prng_next(secret: Int) -> Int {
  secret
  |> fn(secret) { mix(secret, secret * 64) }
  |> prune
  |> fn(secret) { mix(secret, secret / 32) }
  |> prune
  |> fn(secret) { mix(secret, secret * 2048) }
  |> prune
}

fn parse_int(s: String) -> Int {
  case int.parse(s) {
    Ok(n) -> n
    Error(_) -> panic as { "Invalid integer: " <> s }
  }
}

fn parse(input: String) -> List(Int) {
  string.split(input, "\n")
  |> list.map(parse_int)
}

pub fn part1(input: String) -> Int {
  let nums = parse(input)

  list.map(nums, fn(num) {
    int.range(0, 2000, num, fn(num, _) { prng_next(num) })
  })
  |> int.sum
}

type Gains =
  dict.Dict(List(Int), Int)

type PriceStep {
  PriceStep(price: Int, delta: Int)
}

fn collect_gains(
  prices: List(PriceStep),
  gains: Gains,
  seen: set.Set(List(Int)),
) -> Gains {
  case prices {
    [a, b, c, d, ..] -> {
      let deltas = [a, b, c, d] |> list.map(fn(step) { step.delta })

      let #(gains, seen) = case set.contains(seen, deltas) {
        True -> #(gains, seen)
        False -> #(
          dict.upsert(gains, deltas, fn(curr) {
            option.unwrap(curr, 0) + d.price
          }),
          set.insert(seen, deltas),
        )
      }

      collect_gains(list.drop(prices, 1), gains, seen)
    }
    _ -> gains
  }
}

fn gains_for_person(gains: Gains, starting_num: Int) -> Gains {
  let prices =
    int.range(0, 2000, #(starting_num, []), fn(acc, _) {
      let #(curr_num, prices) = acc
      let curr_price = curr_num % 10
      let next_num = prng_next(curr_num)
      let next_price = next_num % 10
      #(next_num, [
        PriceStep(price: next_price, delta: next_price - curr_price),
        ..prices
      ])
    })
    |> pair.second
    |> list.reverse

  collect_gains(prices, gains, set.new())
}

pub fn part2(input: String) -> Int {
  let nums = parse(input)
  let gains = list.fold(nums, dict.new(), gains_for_person)

  dict.values(gains)
  |> list.reduce(int.max)
  |> result.lazy_unwrap(fn() { panic as "No solution found" })
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
