# fgof-termios

Terminal mode helpers for modern Fortran tools.

`fgof-termios` is intended to be a small, standalone library for safe terminal mode changes in shells, REPLs, editors, PTY tools, and interactive test harnesses.

It is part of the [FortranGoingOnForty lib-modules](https://github.com/FortranGoingOnForty/lib-modules) catalog, but it is intended to stand on its own as a normal `fpm` package.

Current v1 target:

- raw and canonical mode guards
- echo control helpers
- terminal size queries
- restore-first lifecycle semantics that compose cleanly with `fgof-pty` and `fgof-lineedit`
- a small high-level API that app authors can trust

Future scope:

- signal-aware restore helpers
- richer cursor or terminal capability helpers in companion packages
- higher-level key decoding in `fgof-keys`

## Status

Core termios backend is in place.

Implemented today:

- public `fgof_termios` and `fgof_termios_types` modules
- stable guard state with explicit mode and error constants
- explicit guard binding with default or chosen file descriptor
- POSIX-backed tty validation and original terminal-state capture on bind
- real raw mode, cbreak mode, and explicit echo transitions applied through the captured snapshot
- idempotent restore semantics for guard lifecycle
- safe rebinding that restores the previous tty before switching fds
- stale-fd protection that rejects descriptor reuse instead of restoring into the wrong terminal
- terminal-size queries from an explicit fd or default stdin
- tracked `fpm` examples for restore-first and terminal-size flows
- smoke-test coverage with CI wiring

Still to implement:

- signal-safety hardening
- richer integration examples

## Why Use It

- terminal mode handling is still low-level and repeatedly hand-rolled in Fortran apps
- `fgof-pty` and `fgof-lineedit` both benefit from a dedicated foundational package here
- app authors want a reusable library surface, not only app-local termios shims

## Public API Shape

Primary modules:

- `fgof_termios`
- `fgof_termios_types`

Public types:

- `termios_guard`
- `terminal_size`

Current public procedures:

- `bind_guard`
- `disable_echo`
- `enable_echo`
- `enter_cbreak_mode`
- `enter_raw_mode`
- `get_terminal_size`
- `restore_guard`

`get_terminal_size()` uses file descriptor `0` by default. Pass an explicit fd when your app is reading size from a PTY or a non-stdin terminal.

If `bind_guard()` is called on a guard that still owes a restore, it restores the previous tty first and only switches to the new fd if that restore succeeds. Restore and apply operations also verify that the bound fd still refers to the original terminal, so stale descriptor reuse fails safely instead of mutating a different tty.

`restore_guard()` is a no-op when no restore is pending, so callers can safely use it in straightforward cleanup paths.

`enter_raw_mode()` uses the normal raw default of echo off. `enable_echo()` and `disable_echo()` are explicit overrides for the active mode, so callers can opt into raw-with-echo or cbreak-without-echo when they want that behavior.

## Quick Start

```fortran
program demo_termios
  use fgof_termios, only : bind_guard, disable_echo, enter_cbreak_mode, get_terminal_size, restore_guard
  use fgof_termios_types, only : FGOF_TERMIOS_ERR_NONE, terminal_size, termios_guard
  implicit none

  type(termios_guard) :: guard
  type(terminal_size) :: size_info

  call bind_guard(guard)
  if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) stop 1

  size_info = get_terminal_size(guard%fd)
  call enter_cbreak_mode(guard)
  call disable_echo(guard)
  call restore_guard(guard)
  if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) stop 1
end program demo_termios
```

Tracked example programs:

```bash
fpm run --example restore_first
fpm run --example terminal_size_query
```

## Build And Test

```bash
fpm test
```

That is the baseline verification command locally and in CI.

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on reusable terminal mode primitives, not a full TUI toolkit
- the first release should solve safe raw, cbreak, and echo transitions well before it grows broader terminal helpers
- future `fgof-keys` should be able to depend on this package without inheriting PTY or line-editing policy

## Composition

- `fgof-pty` should own PTY lifecycle and pass the relevant tty fd into `bind_guard` or `get_terminal_size`
- `fgof-lineedit` should own buffer, history, and completion state while `fgof-termios` owns mode transitions
- future `fgof-keys` should decode raw input bytes on top of this package instead of re-implementing terminal mode policy

## License

MIT
