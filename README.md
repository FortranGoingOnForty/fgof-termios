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
- scaffold `termios_guard` and `terminal_size` types
- guard lifecycle placeholders for raw mode, echo suppression, and restore
- smoke-test coverage with CI wiring

Still to implement:

- POSIX termios backend
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
- `request_raw_mode`
- `request_noecho`
- `restore_guard`
- `terminal_size_of`

## Quick Start

```fortran
program demo_termios
  use fgof_termios, only : bind_guard, request_noecho, request_raw_mode, restore_guard, terminal_size_of
  use fgof_termios_types, only : terminal_size, termios_guard
  implicit none

  type(termios_guard) :: guard
  type(terminal_size) :: size

  call bind_guard(guard)
  call request_raw_mode(guard)
  call request_noecho(guard)
  size = terminal_size_of(24, 80)
  print "(I0,1X,I0)", size%rows, size%columns
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
- the first release should solve safe raw or noecho mode transitions well before it grows broader terminal helpers
- future `fgof-keys` should be able to depend on this package without inheriting PTY or line-editing policy

## License

MIT
