program restore_first
  use fgof_termios, only : bind_guard, disable_echo, enter_raw_mode, get_terminal_size, restore_guard
  use fgof_termios_types, only : FGOF_TERMIOS_ERR_NONE, terminal_size, termios_guard
  implicit none

  type(termios_guard) :: guard
  type(terminal_size) :: size_info

  call bind_guard(guard)
  if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) stop 1

  size_info = get_terminal_size(guard%fd)
  call enter_raw_mode(guard)
  call disable_echo(guard)

  if (size_info%valid) then
    write(*, '(A,I0,A,I0)') "terminal size: ", size_info%rows, "x", size_info%columns
  end if

  call restore_guard(guard)
  if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) stop 1
end program restore_first
