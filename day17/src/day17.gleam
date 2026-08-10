import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

type Registers {
  Registers(a: Int, b: Int, c: Int)
}

fn load_combo(combo: Int, registers: Registers) -> Int {
  case combo {
    0 | 1 | 2 | 3 -> combo
    4 -> registers.a
    5 -> registers.b
    6 -> registers.c
    7 -> panic as "Combo instruction 7 is reserved!"
    _ -> panic as { "Combo out of range: " <> string.inspect(combo) }
  }
}

type VM {
  VM(registers: Registers, program: List(Int), tape: List(Int))
}

fn parse_int(value: String) -> Int {
  case int.parse(value) {
    Ok(value) -> value
    Error(_) -> panic as { "Invalid integer: " <> string.inspect(value) }
  }
}

fn parse_vm(input: String) -> VM {
  let lines = string.split(input, "\n")
  let assert [reg_a, reg_b, reg_c, _, program] = lines

  let parse_reg = fn(line: String) -> Int {
    let assert [_, reg] = string.split(line, ": ")
    parse_int(reg)
  }

  let registers =
    Registers(parse_reg(reg_a), parse_reg(reg_b), parse_reg(reg_c))
  let assert [_, program] = string.split(program, ": ")
  let program = string.split(program, ",") |> list.map(parse_int)

  VM(registers, program, program)
}

type Debugger {
  Debugger(vm: VM, output: List(Int))
}

type Instruction {
  Adv
  Bxl
  Bst
  Jnz
  Bxc
  Out
  Bdv
  Cdv
}

fn parse_instruction(int: Int) -> Instruction {
  case int {
    0 -> Adv
    1 -> Bxl
    2 -> Bst
    3 -> Jnz
    4 -> Bxc
    5 -> Out
    6 -> Bdv
    7 -> Cdv
    _ -> panic as { "Invalid instruction: " <> string.inspect(int) }
  }
}

fn update_a(vm: VM, value: Int) -> VM {
  VM(..vm, registers: Registers(..vm.registers, a: value))
}

fn update_b(vm: VM, value: Int) -> VM {
  VM(..vm, registers: Registers(..vm.registers, b: value))
}

fn update_c(vm: VM, value: Int) -> VM {
  VM(..vm, registers: Registers(..vm.registers, c: value))
}

fn move_tape(vm: VM, tape: List(Int)) -> VM {
  VM(..vm, tape: tape)
}

fn jump(vm: VM, ip: Int) -> VM {
  VM(..vm, tape: list.drop(vm.program, ip))
}

type VmStep {
  Continue(vm: VM, output: option.Option(Int))
  Halt
}

fn output(vm: VM, value: Int) -> VmStep {
  Continue(vm:, output: option.Some(value))
}

fn no_output(vm: VM) -> VmStep {
  Continue(vm:, output: option.None)
}

fn step_vm(vm: VM) -> VmStep {
  case vm.tape {
    [instr, arg, ..tape] -> {
      let dv = fn() {
        let num = vm.registers.a
        let den = int.bitwise_shift_left(1, load_combo(arg, vm.registers))
        num / den
      }

      case parse_instruction(instr) {
        Bxl -> {
          let b = vm.registers.b
          let b = int.bitwise_exclusive_or(b, arg)
          update_b(vm, b) |> move_tape(tape) |> no_output
        }

        Bst -> {
          let b = load_combo(arg, vm.registers) % 8
          update_b(vm, b) |> move_tape(tape) |> no_output
        }

        Jnz -> {
          case vm.registers.a {
            0 -> move_tape(vm, tape) |> no_output
            _ -> jump(vm, arg) |> no_output
          }
        }

        Bxc -> {
          let Registers(a: _, b:, c:) = vm.registers
          let b = int.bitwise_exclusive_or(b, c)
          update_b(vm, b) |> move_tape(tape) |> no_output
        }

        Out -> {
          let out = load_combo(arg, vm.registers) % 8
          move_tape(vm, tape) |> output(out)
        }

        Adv -> update_a(vm, dv()) |> move_tape(tape) |> no_output
        Bdv -> update_b(vm, dv()) |> move_tape(tape) |> no_output
        Cdv -> update_c(vm, dv()) |> move_tape(tape) |> no_output
      }
    }

    _ -> Halt
  }
}

type DebuggerNext {
  ContinueDbg
  HaltDbg
}

fn step_debugger(debugger: Debugger) -> #(Debugger, DebuggerNext) {
  let Debugger(vm:, output:) = debugger

  case step_vm(vm) {
    Continue(vm, step_out) -> {
      let output = case step_out {
        option.Some(value) -> [value, ..output]
        option.None -> output
      }

      #(Debugger(vm: vm, output: output), ContinueDbg)
    }
    Halt -> #(debugger, HaltDbg)
  }
}

fn run_debugger(debugger: Debugger, reverse_output rev: Bool) -> List(Int) {
  let #(debugger, next) = step_debugger(debugger)
  case next {
    ContinueDbg -> run_debugger(debugger, rev)

    HaltDbg ->
      case rev {
        True -> list.reverse(debugger.output)
        False -> debugger.output
      }
  }
}

fn debug(vm: VM, reverse_output rev: Bool) -> List(Int) {
  run_debugger(Debugger(vm: vm, output: []), rev)
}

pub fn part1(input: String) -> String {
  let vm = parse_vm(input)
  let output = debug(vm, reverse_output: True)
  output |> list.map(int.to_string) |> string.join(",")
}

fn print_tape(tape: List(Int)) {
  case tape {
    [instr, arg, ..tape] -> {
      io.println(
        string.inspect(parse_instruction(instr)) <> " " <> int.to_string(arg),
      )
      print_tape(tape)
    }
    _ -> Nil
  }
}

fn has_prefix(haystack: List(Int), needle: List(Int)) -> Bool {
  case haystack, needle {
    _, [] -> True
    [], [_, ..] -> False
    [h, ..h_rest], [n, ..n_rest] -> h == n && has_prefix(h_rest, n_rest)
  }
}

fn reconstruct_a_rec(
  vm: VM,
  reversed_prog: List(Int),
  hi: Int,
) -> Result(Int, Nil) {
  let start = case hi {
    0 -> 1
    _ -> 0
  }

  int.range(start, 8, Error(Nil), fn(solution, i) {
    use <- bool.guard(when: solution != Error(Nil), return: solution)

    let a = hi + i
    let vm = vm |> update_a(a)
    let output = debug(vm, reverse_output: False)

    use <- bool.guard(when: output == reversed_prog, return: Ok(a))
    case has_prefix(reversed_prog, output) {
      True -> reconstruct_a_rec(vm, reversed_prog, a * 8)
      False -> Error(Nil)
    }
  })
}

fn reconstruct_a(vm: VM) -> Int {
  reconstruct_a_rec(vm, list.reverse(vm.program), 0)
  |> result.lazy_unwrap(fn() { panic as "No solution found!" })
}

pub fn part2(input: String) -> Int {
  let vm = parse_vm(input)

  int.range(0, int.min(8, list.length(vm.tape)), Nil, fn(_, i) {
    io.println("Dropping " <> int.to_string(i) <> ":")
    print_tape(list.drop(vm.tape, i))
    io.println("")
  })

  // My program is:
  // bst 4 (reg A)      B <- A % 8
  // bxl 7              B <- B ^ 0b111
  // cdv 5 (reg B)      C <- A / 2^B
  // adv 3 (lit 3)      A <- A / 2^3
  // bxc _              B <- B ^ C
  // bxl 7              B <- B ^ 0b111
  // out 5 (reg B)      Output <- B % 8
  // jnz 0
  //
  // hypothesis:
  // in each step, i take the top three bits of A, call that B
  // i bitflip B and shift A right by that many bits, grab top three bits, call that C
  // i bitxor B and C, output that
  //
  // Yeah, don't wanna do that, I'll just brute force reconstruct :D

  reconstruct_a(vm)
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
