import gleam/int
import gleam/list
import gleam/string

fn parse_int(s: String) -> Int {
  let assert Ok(i) = int.parse(s)
  i
}

pub type Block {
  File(id: Int, size: Int)
  Free(size: Int)
}

pub fn partial_sum(from lo: Int, to hi: Int) -> Int {
  let one_to_n = fn(n) { n * { n + 1 } / 2 }
  one_to_n(hi) - one_to_n(lo - 1)
}

pub fn parse_input(input: String) -> List(Block) {
  string.split(input, "")
  |> list.map(parse_int)
  |> list.sized_chunk(2)
  |> list.index_map(fn(chunk, id) {
    case chunk {
      [first, second] -> [File(id, first), Free(second)]
      [first] -> [File(id, first)]
      _ -> panic
    }
  })
  |> list.flatten
}
