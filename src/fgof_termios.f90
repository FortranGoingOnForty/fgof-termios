module fgof_termios
  use fgof_termios_types, only : &
    FGOF_TERMIOS_ERR_INVALID_FD, &
    FGOF_TERMIOS_ERR_NONE, &
    FGOF_TERMIOS_ERR_UNBOUND_GUARD, &
    FGOF_TERMIOS_MODE_CBREAK, &
    FGOF_TERMIOS_MODE_NONE, &
    FGOF_TERMIOS_MODE_RAW, &
    terminal_size, &
    termios_guard
  implicit none
  private

  public :: bind_guard
  public :: enter_cbreak_mode
  public :: enter_raw_mode
  public :: disable_echo
  public :: enable_echo
  public :: restore_guard

contains

  subroutine bind_guard(guard, fd)
    type(termios_guard), intent(inout) :: guard
    integer, intent(in), optional :: fd

    guard = termios_guard()
    if (present(fd)) then
      guard%fd = fd
    else
      guard%fd = 0
    end if

    if (guard%fd < 0) then
      call set_guard_error(guard, FGOF_TERMIOS_ERR_INVALID_FD, "guard fd must be nonnegative")
      return
    end if

    guard%bound = .true.
    call clear_guard_error(guard)
  end subroutine bind_guard

  subroutine enter_raw_mode(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. ensure_bound(guard)) return
    guard%snapshot_captured = .true.
    guard%restore_needed = .true.
    guard%active_mode = FGOF_TERMIOS_MODE_RAW
    call clear_guard_error(guard)
  end subroutine enter_raw_mode

  subroutine enter_cbreak_mode(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. ensure_bound(guard)) return
    guard%snapshot_captured = .true.
    guard%restore_needed = .true.
    guard%active_mode = FGOF_TERMIOS_MODE_CBREAK
    call clear_guard_error(guard)
  end subroutine enter_cbreak_mode

  subroutine disable_echo(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. ensure_bound(guard)) return
    guard%snapshot_captured = .true.
    guard%restore_needed = .true.
    guard%echo_disabled = .true.
    call clear_guard_error(guard)
  end subroutine disable_echo

  subroutine enable_echo(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. ensure_bound(guard)) return
    guard%snapshot_captured = .true.
    guard%restore_needed = .true.
    guard%echo_disabled = .false.
    call clear_guard_error(guard)
  end subroutine enable_echo

  subroutine restore_guard(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. guard%bound) then
      call clear_guard_error(guard)
      return
    end if

    guard%active_mode = FGOF_TERMIOS_MODE_NONE
    guard%snapshot_captured = .false.
    guard%restore_needed = .false.
    guard%echo_disabled = .false.
    call clear_guard_error(guard)
  end subroutine restore_guard

  logical function ensure_bound(guard) result(is_ready)
    type(termios_guard), intent(inout) :: guard

    if (.not. guard%bound) then
      call set_guard_error(guard, FGOF_TERMIOS_ERR_UNBOUND_GUARD, "bind_guard must be called before mode changes")
      is_ready = .false.
      return
    end if

    is_ready = .true.
  end function ensure_bound

  subroutine clear_guard_error(guard)
    type(termios_guard), intent(inout) :: guard

    guard%last_error_code = FGOF_TERMIOS_ERR_NONE
    if (allocated(guard%last_error_message)) then
      deallocate(guard%last_error_message)
    end if
    guard%last_error_message = ""
  end subroutine clear_guard_error

  subroutine set_guard_error(guard, code, message)
    type(termios_guard), intent(inout) :: guard
    integer, intent(in) :: code
    character(len=*), intent(in) :: message

    guard%last_error_code = code
    if (allocated(guard%last_error_message)) then
      deallocate(guard%last_error_message)
    end if
    guard%last_error_message = message
  end subroutine set_guard_error
end module fgof_termios
