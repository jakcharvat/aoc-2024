import gleam/bool
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/result

fn num_digits(x: Int) -> Int {
  let log = fn(x: Float) {
    float.logarithm(x) |> result.lazy_unwrap(fn() { panic })
  }
  let log10 = fn(x: Int) { log(int.to_float(x)) /. log(10.0) }
  { log10(x) |> float.truncate } + 1
}

fn split_digits(x: Int) -> Result(#(Int, Int), Nil) {
  let digits = num_digits(x)
  use <- bool.guard(digits % 2 == 1, return: Error(Nil))

  let d =
    int.power(10, int.to_float(digits / 2))
    |> result.lazy_unwrap(fn() { panic })
    |> float.truncate

  Ok(#(x / d, x % d))
}

type Memo =
  dict.Dict(#(Int, Int), Int)

fn simulate_stone(stone: Int, iters: Int, memo: Memo) -> #(Int, Memo) {
  let try_memo = fn(otherwise) {
    dict.get(memo, #(stone, iters))
    |> result.map(fn(x) { #(x, memo) })
    |> result.lazy_unwrap(otherwise)
  }

  use <- try_memo
  use <- bool.guard(iters == 0, return: #(1, memo))

  let #(res, memo) = case stone {
    0 -> simulate_stone(1, iters - 1, memo)
    x -> {
      case split_digits(x) {
        Ok(#(a, b)) -> {
          let #(res_a, memo) = simulate_stone(a, iters - 1, memo)
          let #(res_b, memo) = simulate_stone(b, iters - 1, memo)
          #(res_a + res_b, memo)
        }

        Error(_) -> simulate_stone(x * 2024, iters - 1, memo)
      }
    }
  }

  #(res, dict.insert(memo, #(stone, iters), res))
}

pub fn part2(nums: List(Int)) -> Int {
  let #(res, _) =
    list.fold(nums, #(0, dict.new()), fn(acc, n) {
      let #(acc, memo) = acc
      let #(res, memo) = simulate_stone(n, 75, memo)
      #(acc + res, memo)
    })

  res
}
