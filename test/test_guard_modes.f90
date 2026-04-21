program test_guard_modes
  use fgof_termios, only : bind_guard, disable_echo, enable_echo, enter_cbreak_mode, enter_raw_mode
  use fgof_termios_types, only : &
    FGOF_TERMIOS_ERR_NONE, &
    FGOF_TERMIOS_MODE_CBREAK, &
    FGOF_TERMIOS_MODE_RAW, &
    termios_guard
  use termios_test_support, only : close_fd, open_test_pty
  implicit none

  call test_mode_switching()
  call test_echo_switching()
  call test_success_clears_error()

contains

  subroutine test_mode_switching()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call bind_guard(guard, slave_fd)
    call enter_raw_mode(guard)
    if (guard%active_mode /= FGOF_TERMIOS_MODE_RAW) error stop "raw mode should become active"
    if (.not. guard%snapshot_captured) error stop "raw mode should mark a captured snapshot"
    if (.not. guard%restore_needed) error stop "raw mode should require restore"

    call enter_cbreak_mode(guard)
    if (guard%active_mode /= FGOF_TERMIOS_MODE_CBREAK) error stop "cbreak mode should replace the active mode"
    if (.not. guard%snapshot_captured) error stop "cbreak mode should keep the snapshot contract"
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_mode_switching

  subroutine test_echo_switching()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call bind_guard(guard, slave_fd)
    call disable_echo(guard)
    if (.not. guard%echo_disabled) error stop "disable_echo should mark echo as disabled"
    if (.not. guard%restore_needed) error stop "echo changes should require restore"

    call enable_echo(guard)
    if (guard%echo_disabled) error stop "enable_echo should clear the echo-disabled state"
    if (.not. guard%snapshot_captured) error stop "echo changes should preserve snapshot intent"
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_echo_switching

  subroutine test_success_clears_error()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call enter_raw_mode(guard)
    call open_test_pty(master_fd, slave_fd)
    call bind_guard(guard, slave_fd)
    call enter_raw_mode(guard)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "successful transitions should clear prior errors"
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_success_clears_error
end program test_guard_modes
