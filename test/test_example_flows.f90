program test_example_flows
  use fgof_termios, only : bind_guard, disable_echo, enter_cbreak_mode, get_terminal_size, restore_guard
  use fgof_termios_types, only : FGOF_TERMIOS_ERR_NONE, terminal_size, termios_guard
  use termios_test_support, only : close_fd, expect_state, open_test_pty, seed_test_tty_defaults, set_test_terminal_size
  implicit none

  call test_restore_first_flow()

contains

  subroutine test_restore_first_flow()
    type(termios_guard) :: guard
    type(terminal_size) :: size_info
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call seed_test_tty_defaults(slave_fd)
    call set_test_terminal_size(slave_fd, 55, 144)

    call bind_guard(guard, slave_fd)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "bind should succeed in example flow"

    size_info = get_terminal_size(guard%fd)
    if (.not. size_info%valid) error stop "example flow should observe a valid terminal size"
    if (size_info%rows /= 55) error stop "example flow should preserve the seeded row count"
    if (size_info%columns /= 144) error stop "example flow should preserve the seeded column count"

    call enter_cbreak_mode(guard)
    call disable_echo(guard)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "mode changes should succeed in example flow"
    call expect_state(slave_fd, .false., .false., .true., 1, 0, "example flow should enter cbreak mode with echo disabled")

    call restore_guard(guard)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "restore should succeed in example flow"
    call expect_state(slave_fd, .true., .true., .true., 1, 0, "example flow should restore the original tty state")

    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_restore_first_flow
end program test_example_flows
