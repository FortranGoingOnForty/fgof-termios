program test_terminal_size
  use fgof_termios, only : get_terminal_size
  use fgof_termios_types, only : terminal_size
  use termios_test_support, only : close_fd, open_test_pipe, open_test_pty, set_test_terminal_size
  implicit none

  call test_terminal_size_success()
  call test_terminal_size_non_tty()
  call test_terminal_size_invalid_fd()

contains

  subroutine test_terminal_size_success()
    type(terminal_size) :: size_info
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call set_test_terminal_size(slave_fd, 42, 120)
    size_info = get_terminal_size(slave_fd)

    if (.not. size_info%valid) error stop "terminal size query should succeed on a tty"
    if (size_info%rows /= 42) error stop "terminal size query should return seeded rows"
    if (size_info%columns /= 120) error stop "terminal size query should return seeded columns"
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_terminal_size_success

  subroutine test_terminal_size_non_tty()
    type(terminal_size) :: size_info
    integer :: read_fd
    integer :: write_fd

    call open_test_pipe(read_fd, write_fd)
    size_info = get_terminal_size(read_fd)

    if (size_info%valid) error stop "terminal size query should fail on a non-tty fd"
    if (size_info%rows /= 0) error stop "failed terminal size query should leave rows at zero"
    if (size_info%columns /= 0) error stop "failed terminal size query should leave columns at zero"
    call close_fd(read_fd)
    call close_fd(write_fd)
  end subroutine test_terminal_size_non_tty

  subroutine test_terminal_size_invalid_fd()
    type(terminal_size) :: size_info

    size_info = get_terminal_size(-1)
    if (size_info%valid) error stop "negative fd should not produce a valid terminal size"
    if (size_info%rows /= 0) error stop "negative fd should leave rows at zero"
    if (size_info%columns /= 0) error stop "negative fd should leave columns at zero"
  end subroutine test_terminal_size_invalid_fd
end program test_terminal_size
