program test_guard_binding
  use fgof_termios, only : bind_guard, disable_echo, enter_raw_mode
  use fgof_termios_types, only : &
    FGOF_TERMIOS_ERR_INVALID_FD, &
    FGOF_TERMIOS_ERR_NONE, &
    FGOF_TERMIOS_ERR_UNBOUND_GUARD, &
    FGOF_TERMIOS_MODE_NONE, &
    termios_guard
  implicit none

  call test_default_bind()
  call test_explicit_bind()
  call test_invalid_fd()
  call test_unbound_error()

contains

  subroutine test_default_bind()
    type(termios_guard) :: guard

    call bind_guard(guard)
    if (.not. guard%bound) error stop "default bind should succeed"
    if (guard%fd /= 0) error stop "default bind should use stdin fd"
    if (guard%active_mode /= FGOF_TERMIOS_MODE_NONE) error stop "fresh guard should start in no mode"
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_NONE) error stop "successful bind should clear errors"
  end subroutine test_default_bind

  subroutine test_explicit_bind()
    type(termios_guard) :: guard

    call bind_guard(guard, 9)
    if (.not. guard%bound) error stop "explicit bind should succeed"
    if (guard%fd /= 9) error stop "explicit bind should preserve fd"
  end subroutine test_explicit_bind

  subroutine test_invalid_fd()
    type(termios_guard) :: guard

    call bind_guard(guard, -3)
    if (guard%bound) error stop "invalid fd should not bind the guard"
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_INVALID_FD) error stop "invalid fd should set the invalid-fd error"
    if (.not. allocated(guard%last_error_message)) error stop "invalid fd should preserve an error message"
    if (len(guard%last_error_message) == 0) error stop "invalid fd error message should not be empty"
  end subroutine test_invalid_fd

  subroutine test_unbound_error()
    type(termios_guard) :: guard

    call enter_raw_mode(guard)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_UNBOUND_GUARD) error stop "raw mode on an unbound guard should fail cleanly"
    call disable_echo(guard)
    if (guard%last_error_code /= FGOF_TERMIOS_ERR_UNBOUND_GUARD) error stop "echo changes on an unbound guard should fail cleanly"
  end subroutine test_unbound_error
end program test_guard_binding
