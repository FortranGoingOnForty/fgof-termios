program test_guard_binding
  use fgof_termios, only : bind_guard, disable_echo, enter_raw_mode
  use fgof_termios_types, only : &
    FGOF_TERMIOS_ERR_CAPTURE_FAILED, &
    FGOF_TERMIOS_ERR_INVALID_FD, &
    FGOF_TERMIOS_ERR_NONE, &
    FGOF_TERMIOS_ERR_NOT_A_TTY, &
    FGOF_TERMIOS_ERR_RESTORE_FAILED, &
    FGOF_TERMIOS_ERR_UNBOUND_GUARD, &
    termios_guard
  use termios_test_support, only : close_fd, expect_state, open_test_pipe, open_test_pty, seed_test_tty_defaults
  implicit none

  call test_tty_bind()
  call test_invalid_fd()
  call test_non_tty_fd()
  call test_rebind_restores_previous_tty()
  call test_rebind_failure_preserves_original_guard()
  call test_unbound_error()

contains

  subroutine test_tty_bind()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call bind_guard(guard, slave_fd)
    if (.not. guard%bound) error stop "tty bind should succeed"
    if (.not. guard%tty) error stop "tty bind should mark the guard as tty-backed"
    if (guard%fd /= slave_fd) error stop "tty bind should preserve the chosen fd"
    if (.not. guard%snapshot_captured) error stop "tty bind should capture the original terminal state"
    if (.not. allocated(guard%captured_state)) error stop "tty bind should store the captured state"
    if (size(guard%captured_state) <= 0) error stop "tty bind should capture a nonempty state buffer"
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "successful bind should clear errors"
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_tty_bind

  subroutine test_invalid_fd()
    type(termios_guard) :: guard

    call bind_guard(guard, -3)
    if (guard%bound) error stop "invalid fd should not bind the guard"
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_INVALID_FD) error stop "invalid fd should set the invalid-fd error"
    if (.not. allocated(guard%last_error_message)) error stop "invalid fd should preserve an error message"
    if (len(guard%last_error_message) == 0) error stop "invalid fd error message should not be empty"
  end subroutine test_invalid_fd

  subroutine test_non_tty_fd()
    type(termios_guard) :: guard
    integer :: read_fd
    integer :: write_fd

    call open_test_pipe(read_fd, write_fd)
    call bind_guard(guard, read_fd)
    if (guard%bound) error stop "non-tty bind should fail cleanly"
    if (guard%tty) error stop "non-tty bind should not mark the guard as tty-backed"
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NOT_A_TTY) error stop "non-tty bind should surface the not-a-tty error"
    if (allocated(guard%captured_state)) then
      if (size(guard%captured_state) /= 0) error stop "non-tty bind should not preserve a captured state"
    end if
    call close_fd(write_fd)
    call close_fd(read_fd)
  end subroutine test_non_tty_fd

  subroutine test_rebind_restores_previous_tty()
    type(termios_guard) :: guard
    integer :: first_master_fd
    integer :: first_slave_fd
    integer :: second_master_fd
    integer :: second_slave_fd

    call open_test_pty(first_master_fd, first_slave_fd)
    call seed_test_tty_defaults(first_slave_fd)
    call bind_guard(guard, first_slave_fd)
    call enter_raw_mode(guard)
    call disable_echo(guard)

    call open_test_pty(second_master_fd, second_slave_fd)
    call seed_test_tty_defaults(second_slave_fd)
    call bind_guard(guard, second_slave_fd)

    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "rebind should succeed after restoring the old tty"
    if (guard%fd /= second_slave_fd) error stop "rebind should switch the guard to the new fd"
    call expect_state(first_slave_fd, .true., .true., .true., 1, 0, "rebind should restore the previous tty before switching")
    call expect_state(second_slave_fd, .true., .true., .true., 1, 0, "rebind should not mutate the new tty during capture")
    call close_fd(second_slave_fd)
    call close_fd(second_master_fd)
    call close_fd(first_slave_fd)
    call close_fd(first_master_fd)
  end subroutine test_rebind_restores_previous_tty

  subroutine test_rebind_failure_preserves_original_guard()
    type(termios_guard) :: guard
    integer :: first_bound_fd
    integer :: first_master_fd
    integer :: first_slave_fd
    integer :: second_master_fd
    integer :: second_slave_fd

    call open_test_pty(first_master_fd, first_slave_fd)
    call seed_test_tty_defaults(first_slave_fd)
    call bind_guard(guard, first_slave_fd)
    call enter_raw_mode(guard)
    call disable_echo(guard)
    first_bound_fd = first_slave_fd
    call close_fd(first_slave_fd)

    call open_test_pty(second_master_fd, second_slave_fd)
    call seed_test_tty_defaults(second_slave_fd)
    call bind_guard(guard, second_slave_fd)

    if (guard%last_error_code /= FGOF_TERMIOS_ERR_RESTORE_FAILED) error stop "rebind should fail if the old tty cannot be restored"
    if (guard%fd /= first_bound_fd) error stop "failed rebind should preserve the original bound fd"
    if (.not. guard%restore_needed) error stop "failed rebind should preserve pending restore state"
    call expect_state(second_slave_fd, .true., .true., .true., 1, 0, "failed rebind should not touch the new tty")
    call close_fd(second_slave_fd)
    call close_fd(second_master_fd)
    call close_fd(first_master_fd)
  end subroutine test_rebind_failure_preserves_original_guard

  subroutine test_unbound_error()
    type(termios_guard) :: guard

    call enter_raw_mode(guard)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_UNBOUND_GUARD) error stop "raw mode on an unbound guard should fail cleanly"
    call disable_echo(guard)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_UNBOUND_GUARD) error stop "echo changes on an unbound guard should fail cleanly"
  end subroutine test_unbound_error
end program test_guard_binding
