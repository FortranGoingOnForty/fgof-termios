program test_scaffold
  use fgof_termios, only : bind_guard, request_noecho, request_raw_mode, restore_guard, terminal_size_of
  use fgof_termios_types, only : terminal_size, termios_guard
  implicit none

  type(termios_guard) :: guard
  type(terminal_size) :: size

  call bind_guard(guard)
  if (.not. guard%bound) error stop "guard should bind"
  if (guard%fd /= 0) error stop "default guard should use stdin fd"

  call request_raw_mode(guard)
  call request_noecho(guard)
  if (.not. guard%raw_requested) error stop "raw mode should be requested"
  if (.not. guard%noecho_requested) error stop "noecho should be requested"

  call restore_guard(guard)
  if (guard%raw_requested) error stop "restore should clear raw mode"
  if (guard%noecho_requested) error stop "restore should clear noecho"

  size = terminal_size_of(24, 80)
  if (size%rows /= 24) error stop "terminal rows should round-trip"
  if (size%columns /= 80) error stop "terminal columns should round-trip"
end program test_scaffold
