module fgof_termios
  use fgof_termios_posix, only : TERMIOS_POSIX_CAPTURE_FAILED, TERMIOS_POSIX_NOT_TTY, TERMIOS_POSIX_OK, posix_capture_state
  use fgof_termios_types, only : &
    FGOF_TERMIOS_ERR_CAPTURE_FAILED, &
    FGOF_TERMIOS_ERR_INVALID_FD, &
    FGOF_TERMIOS_ERR_NONE, &
    FGOF_TERMIOS_ERR_NOT_A_TTY, &
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
    integer :: capture_status
    logical :: tty_ready
    character(len=:), allocatable :: capture_message

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

    call posix_capture_state(guard%fd, guard%captured_state, tty_ready, capture_status, capture_message)
    guard%tty = tty_ready
    select case (capture_status)
    case (TERMIOS_POSIX_OK)
      continue
    case (TERMIOS_POSIX_NOT_TTY)
      call set_guard_error(guard, FGOF_TERMIOS_ERR_NOT_A_TTY, capture_message)
      return
    case (TERMIOS_POSIX_CAPTURE_FAILED)
      call set_guard_error(guard, FGOF_TERMIOS_ERR_CAPTURE_FAILED, capture_message)
      return
    case default
      call set_guard_error(guard, FGOF_TERMIOS_ERR_CAPTURE_FAILED, "terminal state capture failed")
      return
    end select

    guard%bound = .true.
    guard%snapshot_captured = allocated(guard%captured_state) .and. size(guard%captured_state) > 0
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
