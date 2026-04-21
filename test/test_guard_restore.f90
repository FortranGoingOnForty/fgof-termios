program test_guard_restore
  use fgof_termios, only : bind_guard, disable_echo, enter_raw_mode, restore_guard
  use fgof_termios_types, only : &
    FGOF_TERMIOS_ERR_NONE, &
    FGOF_TERMIOS_MODE_NONE, &
    termios_guard
  implicit none

  call test_restore_resets_state()
  call test_restore_is_idempotent()
  call test_rebind_resets_state()

contains

  subroutine test_restore_resets_state()
    type(termios_guard) :: guard

    call bind_guard(guard)
    call enter_raw_mode(guard)
    call disable_echo(guard)
    call restore_guard(guard)

    if (guard%active_mode /= FGOF_TERMIOS_MODE_NONE) error stop "restore should clear the active mode"
    if (guard%snapshot_captured) error stop "restore should clear the snapshot marker"
    if (guard%restore_needed) error stop "restore should clear the restore-needed flag"
    if (guard%echo_disabled) error stop "restore should clear echo-disabled state"
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "restore should leave the guard error-free"
  end subroutine test_restore_resets_state

  subroutine test_restore_is_idempotent()
    type(termios_guard) :: guard

    call restore_guard(guard)
    call bind_guard(guard)
    call restore_guard(guard)
    call restore_guard(guard)

    if (guard%active_mode /= FGOF_TERMIOS_MODE_NONE) error stop "repeated restore should remain safe"
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "repeated restore should not create an error"
  end subroutine test_restore_is_idempotent

  subroutine test_rebind_resets_state()
    type(termios_guard) :: guard

    call bind_guard(guard)
    call enter_raw_mode(guard)
    call disable_echo(guard)
    call bind_guard(guard, 3)

    if (.not. guard%bound) error stop "rebind should keep the guard bound"
    if (guard%fd /= 3) error stop "rebind should replace the bound fd"
    if (guard%active_mode /= FGOF_TERMIOS_MODE_NONE) error stop "rebind should reset the active mode"
    if (guard%snapshot_captured) error stop "rebind should reset the snapshot marker"
    if (guard%restore_needed) error stop "rebind should clear restore-needed state"
    if (guard%echo_disabled) error stop "rebind should clear echo-disabled state"
  end subroutine test_rebind_resets_state
end program test_guard_restore
