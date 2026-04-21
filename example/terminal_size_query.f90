program terminal_size_query
  use fgof_termios, only : get_terminal_size
  use fgof_termios_types, only : terminal_size
  implicit none

  type(terminal_size) :: size_info

  size_info = get_terminal_size()
  if (.not. size_info%valid) then
    write(*, '(A)') "stdin is not a terminal"
    stop 0
  end if

  write(*, '(A,I0,A,I0)') "stdin size: ", size_info%rows, "x", size_info%columns
end program terminal_size_query
