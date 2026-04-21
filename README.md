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

Initial scaffold is in place.

Implemented today:

- public `fgof_termios` and `fgof_termios_types` modules
- stable guard state with explicit mode and error constants
- explicit guard binding with default or chosen file descriptor
- POSIX-backed tty validation and original terminal-state capture on bind
- idempotent restore semantics for guard lifecycle
- public contract for raw mode, cbreak mode, and echo toggles
- smoke-test coverage with CI wiring

Still to implement:

- raw, cbreak, and echo mode transitions
- terminal-size queries from real file descriptors
- restore-on-failure and signal-safety hardening

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
- `restore_guard`

## Quick Start

```fortran
program demo_termios
  use fgof_termios, only : bind_guard, disable_echo, enter_raw_mode, restore_guard
  use fgof_termios_types, only : termios_guard
  implicit none

  type(termios_guard) :: guard

  call bind_guard(guard)
  call enter_raw_mode(guard)
  call disable_echo(guard)
  call restore_guard(guard)
end program demo_termios
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

## License

MIT
