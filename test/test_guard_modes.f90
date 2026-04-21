program test_guard_modes
  use fgof_termios, only : bind_guard, disable_echo, enable_echo, enter_cbreak_mode, enter_raw_mode
  use fgof_termios_types, only : &
    FGOF_TERMIOS_ERR_APPLY_FAILED, &
    FGOF_TERMIOS_ERR_NONE, &
    FGOF_TERMIOS_MODE_CBREAK, &
    FGOF_TERMIOS_MODE_NONE, &
    FGOF_TERMIOS_MODE_RAW, &
    termios_guard
  use termios_test_support, only : close_fd, expect_raw_profile, expect_state, open_test_pty, seed_test_tty_defaults
  implicit none

  call test_mode_switching()
  call test_echo_switching()
  call test_enable_echo_overrides_raw_profile()
  call test_success_clears_error()
  call test_apply_failure_preserves_state()

contains

  subroutine test_mode_switching()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call seed_test_tty_defaults(slave_fd)
    call bind_guard(guard, slave_fd)
    call expect_state(slave_fd, .true., .true., .true., 1, 0, "seeded tty should start canonical with echo and signals")
    call enter_raw_mode(guard)
    if (guard%active_mode /= FGOF_TERMIOS_MODE_RAW) error stop "raw mode should become active"
    if (.not. guard%snapshot_captured) error stop "raw mode should mark a captured snapshot"
    if (.not. guard%restore_needed) error stop "raw mode should require restore"
    call expect_state(slave_fd, .false., .false., .false., 1, 0, "raw mode should clear canonical, echo, and signals")
    call expect_raw_profile(slave_fd, "raw mode should apply the full raw flag profile")

    call enter_cbreak_mode(guard)
    if (guard%active_mode /= FGOF_TERMIOS_MODE_CBREAK) error stop "cbreak mode should replace the active mode"
    if (.not. guard%snapshot_captured) error stop "cbreak mode should keep the snapshot contract"
    call expect_state(slave_fd, .false., .true., .true., 1, 0, "cbreak mode should keep echo and signals while clearing canonical")
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_mode_switching

  subroutine test_echo_switching()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call seed_test_tty_defaults(slave_fd)
    call bind_guard(guard, slave_fd)
    call disable_echo(guard)
    if (.not. guard%echo_disabled) error stop "disable_echo should mark echo as disabled"
    if (.not. guard%restore_needed) error stop "echo changes should require restore"
    call expect_state(slave_fd, .true., .false., .true., 1, 0, "disable_echo should preserve canonical mode and signals")

    call enable_echo(guard)
    if (guard%echo_disabled) error stop "enable_echo should clear the echo-disabled state"
    if (.not. guard%snapshot_captured) error stop "echo changes should preserve snapshot intent"
    call expect_state(slave_fd, .true., .true., .true., 1, 0, "enable_echo should restore echo from the original snapshot")
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_echo_switching

  subroutine test_enable_echo_overrides_raw_profile()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call seed_test_tty_defaults(slave_fd)
    call bind_guard(guard, slave_fd)
    call enter_raw_mode(guard)
    call enable_echo(guard)

    if (guard%echo_disabled) error stop "enable_echo should clear the echo-disabled flag"
    call expect_state(slave_fd, .false., .true., .false., 1, 0, "enable_echo should turn echo on even under raw mode")
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_enable_echo_overrides_raw_profile

  subroutine test_success_clears_error()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call enter_raw_mode(guard)
    call open_test_pty(master_fd, slave_fd)
    call seed_test_tty_defaults(slave_fd)
    call bind_guard(guard, slave_fd)
    call enter_raw_mode(guard)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "successful transitions should clear prior errors"
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_success_clears_error

  subroutine test_apply_failure_preserves_state()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call seed_test_tty_defaults(slave_fd)
    call bind_guard(guard, slave_fd)
    call close_fd(slave_fd)
    call enter_raw_mode(guard)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_APPLY_FAILED) error stop "apply failure should surface a dedicated error"
    if (guard%active_mode /= FGOF_TERMIOS_MODE_NONE) error stop "apply failure should not update the active mode"
    if (guard%restore_needed) error stop "apply failure should not mark restore as needed"
    call close_fd(master_fd)
  end subroutine test_apply_failure_preserves_state
end program test_guard_modes
