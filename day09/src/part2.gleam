import gleam/list
import gleam/set

import shared.{type Block, File, Free, parse_input, partial_sum}

type FS =
  List(Block)

fn move_left_rec(fs: FS, id: Int, size: Int) -> FS {
  case fs {
    [] -> []

    [File(f_id, f_size), ..rest] if f_id == id -> [File(f_id, f_size), ..rest]

    [File(f_id, f_size), ..rest] -> [
      File(f_id, f_size),
      ..move_left_rec(rest, id, size)
    ]

    [Free(f_size), ..rest] -> {
      case f_size {
        s if s < size -> [Free(f_size), ..move_left_rec(rest, id, size)]
        s if s == size -> [File(id, size), ..rest]
        s if s > size -> [File(id, size), Free(s - size), ..rest]
        _ -> panic as "Invalid ordering"
      }
    }
  }
}

fn move_left(fs: FS, curr: Block) -> FS {
  case curr {
    Free(_) -> fs
    File(f_id, f_size) -> move_left_rec(fs, f_id, f_size)
  }
}

fn remove_duplicates(fs: FS, seen: set.Set(Int)) -> FS {
  case fs {
    [] -> []
    [Free(size), ..rest] -> [Free(size), ..remove_duplicates(rest, seen)]
    [File(id, size), ..rest] -> {
      case set.contains(seen, id) {
        True -> [Free(size), ..remove_duplicates(rest, seen)]
        False -> [
          File(id, size),
          ..remove_duplicates(rest, set.insert(seen, id))
        ]
      }
    }
  }
}

fn compress_fs(fs: FS) -> FS {
  list.reverse(fs)
  |> list.fold(fs, move_left)
}

type Acc {
  Acc(idx: Int, checksum: Int)
}

fn calc_checksum(fs: FS) -> Int {
  list.fold(fs, Acc(0, 0), fn(acc, curr) {
    case curr {
      Free(size) -> Acc(acc.idx + size, acc.checksum)
      File(id, size) ->
        Acc(
          acc.idx + size,
          acc.checksum + partial_sum(acc.idx, acc.idx + size - 1) * id,
        )
    }
  }).checksum
}

pub fn part2(input: String) -> Int {
  let input = parse_input(input)
  let compressed = compress_fs(input)
  let deduped = remove_duplicates(compressed, set.new())

  calc_checksum(deduped)
}
