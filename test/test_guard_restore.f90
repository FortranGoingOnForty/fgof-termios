program test_guard_restore
  use fgof_termios, only : bind_guard, disable_echo, enter_raw_mode, restore_guard
  use fgof_termios_types, only : &
    FGOF_TERMIOS_ERR_NONE, &
    FGOF_TERMIOS_ERR_RESTORE_FAILED, &
    FGOF_TERMIOS_MODE_NONE, &
    FGOF_TERMIOS_MODE_RAW, &
    termios_guard
  use termios_test_support, only : close_fd, expect_state, open_test_pty, seed_test_tty_defaults
  implicit none

  call test_restore_resets_state()
  call test_restore_is_idempotent()
  call test_rebind_resets_state()
  call test_restore_failure_preserves_requested_state()

contains

  subroutine test_restore_resets_state()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call seed_test_tty_defaults(slave_fd)
    call bind_guard(guard, slave_fd)
    call enter_raw_mode(guard)
    call disable_echo(guard)
    call restore_guard(guard)

    if (guard%active_mode /= FGOF_TERMIOS_MODE_NONE) error stop "restore should clear the active mode"
    if (.not. guard%snapshot_captured) error stop "restore should preserve the captured snapshot for later reuse"
    if (guard%restore_needed) error stop "restore should clear the restore-needed flag"
    if (guard%echo_disabled) error stop "restore should clear echo-disabled state"
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "restore should leave the guard error-free"
    call expect_state(slave_fd, .true., .true., .true., 1, 0, "restore should reapply the original tty state")
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_restore_resets_state

  subroutine test_restore_is_idempotent()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call restore_guard(guard)
    call open_test_pty(master_fd, slave_fd)
    call seed_test_tty_defaults(slave_fd)
    call bind_guard(guard, slave_fd)
    call restore_guard(guard)
    call restore_guard(guard)

    if (guard%active_mode /= FGOF_TERMIOS_MODE_NONE) error stop "repeated restore should remain safe"
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "repeated restore should not create an error"
    if (.not. guard%snapshot_captured) error stop "repeated restore should preserve the original snapshot"
    call expect_state(slave_fd, .true., .true., .true., 1, 0, "repeated restore should leave the tty at the original state")
    call close_fd(slave_fd)
    call close_fd(master_fd)
  end subroutine test_restore_is_idempotent

  subroutine test_rebind_resets_state()
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

    if (.not. guard%bound) error stop "rebind should keep the guard bound"
    if (.not. guard%tty) error stop "rebind should keep the guard tty-backed"
    if (guard%fd /= second_slave_fd) error stop "rebind should replace the bound fd"
    if (guard%active_mode /= FGOF_TERMIOS_MODE_NONE) error stop "rebind should reset the active mode"
    if (.not. guard%snapshot_captured) error stop "rebind should recapture the original snapshot"
    if (guard%restore_needed) error stop "rebind should clear restore-needed state"
    if (guard%echo_disabled) error stop "rebind should clear echo-disabled state"
    call expect_state(second_slave_fd, .true., .true., .true., 1, 0, "rebind should leave the new tty in its original state")
    call close_fd(second_slave_fd)
    call close_fd(second_master_fd)
    call close_fd(first_slave_fd)
    call close_fd(first_master_fd)
  end subroutine test_rebind_resets_state

  subroutine test_restore_failure_preserves_requested_state()
    type(termios_guard) :: guard
    integer :: master_fd
    integer :: slave_fd

    call open_test_pty(master_fd, slave_fd)
    call seed_test_tty_defaults(slave_fd)
    call bind_guard(guard, slave_fd)
    call enter_raw_mode(guard)
    call close_fd(slave_fd)
    call restore_guard(guard)

    if (guard%last_error_code /= FGOF_TERMIOS_ERR_RESTORE_FAILED) error stop "restore failure should surface a dedicated error"
    if (guard%active_mode /= FGOF_TERMIOS_MODE_RAW) error stop "restore failure should preserve the active mode"
    if (.not. guard%restore_needed) error stop "restore failure should keep restore-needed state"
    call close_fd(master_fd)
  end subroutine test_restore_failure_preserves_requested_state
end program test_guard_restore
