module fgof_termios
  use fgof_termios_posix, only : &
    TERMIOS_POSIX_APPLY_FAILED, &
    TERMIOS_POSIX_CAPTURE_FAILED, &
    TERMIOS_POSIX_NOT_TTY, &
    TERMIOS_POSIX_OK, &
    TERMIOS_POSIX_RESTORE_FAILED, &
    TERMIOS_POSIX_SIZE_FAILED, &
    posix_apply_state, &
    posix_capture_state, &
    posix_get_terminal_size, &
    posix_restore_state
  use fgof_termios_types, only : &
    FGOF_TERMIOS_ERR_APPLY_FAILED, &
    FGOF_TERMIOS_ERR_CAPTURE_FAILED, &
    FGOF_TERMIOS_ERR_INVALID_FD, &
    FGOF_TERMIOS_ERR_NONE, &
    FGOF_TERMIOS_ERR_NOT_A_TTY, &
    FGOF_TERMIOS_ERR_RESTORE_FAILED, &
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
  public :: get_terminal_size
  public :: restore_guard

contains

  subroutine bind_guard(guard, fd)
    type(termios_guard), intent(inout) :: guard
    type(termios_guard) :: previous_guard
    integer, intent(in), optional :: fd
    integer :: capture_status
    integer :: restore_status
    logical :: tty_ready
    character(len=:), allocatable :: capture_message
    character(len=:), allocatable :: restore_message

    previous_guard = guard
    if (previous_guard%bound .and. previous_guard%restore_needed .and. previous_guard%snapshot_captured) then
      call posix_restore_state(previous_guard%fd, previous_guard%captured_state, restore_status, restore_message)
      if (restore_status == TERMIOS_POSIX_RESTORE_FAILED) then
        guard = previous_guard
        call set_guard_error(guard, FGOF_TERMIOS_ERR_RESTORE_FAILED, restore_message)
        return
      end if
    end if

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
    call apply_guard_state(guard, FGOF_TERMIOS_MODE_RAW, guard%echo_disabled)
  end subroutine enter_raw_mode

  subroutine enter_cbreak_mode(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. ensure_bound(guard)) return
    call apply_guard_state(guard, FGOF_TERMIOS_MODE_CBREAK, guard%echo_disabled)
  end subroutine enter_cbreak_mode

  subroutine disable_echo(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. ensure_bound(guard)) return
    call apply_guard_state(guard, guard%active_mode, .true.)
  end subroutine disable_echo

  subroutine enable_echo(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. ensure_bound(guard)) return
    call apply_guard_state(guard, guard%active_mode, .false.)
  end subroutine enable_echo

  subroutine restore_guard(guard)
    type(termios_guard), intent(inout) :: guard
    integer :: restore_status
    character(len=:), allocatable :: restore_message

    if (.not. guard%bound) then
      call clear_guard_error(guard)
      return
    end if

    if (.not. guard%snapshot_captured) then
      call clear_guard_error(guard)
      return
    end if

    call posix_restore_state(guard%fd, guard%captured_state, restore_status, restore_message)
    if (restore_status == TERMIOS_POSIX_RESTORE_FAILED) then
      call set_guard_error(guard, FGOF_TERMIOS_ERR_RESTORE_FAILED, restore_message)
      return
    end if

    guard%active_mode = FGOF_TERMIOS_MODE_NONE
    guard%restore_needed = .false.
    guard%echo_disabled = .false.
    call clear_guard_error(guard)
  end subroutine restore_guard

  function get_terminal_size(fd) result(size_info)
    type(terminal_size) :: size_info
    integer, intent(in), optional :: fd
    integer :: query_status
    integer :: rows
    integer :: columns
    integer :: selected_fd
    logical :: tty_ready
    character(len=:), allocatable :: query_message

    size_info = terminal_size()
    if (present(fd)) then
      selected_fd = fd
    else
      selected_fd = 0
    end if

    if (selected_fd < 0) return

    call posix_get_terminal_size(selected_fd, rows, columns, tty_ready, query_status, query_message)
    select case (query_status)
    case (TERMIOS_POSIX_OK)
      size_info%rows = rows
      size_info%columns = columns
      size_info%valid = rows > 0 .and. columns > 0
    case (TERMIOS_POSIX_NOT_TTY, TERMIOS_POSIX_SIZE_FAILED)
      continue
    case default
      continue
    end select
  end function get_terminal_size

  logical function ensure_bound(guard) result(is_ready)
    type(termios_guard), intent(inout) :: guard

    if (.not. guard%bound) then
      call set_guard_error(guard, FGOF_TERMIOS_ERR_UNBOUND_GUARD, "bind_guard must be called before mode changes")
      is_ready = .false.
      return
    end if

    is_ready = .true.
  end function ensure_bound

  subroutine apply_guard_state(guard, target_mode, target_echo_disabled)
    type(termios_guard), intent(inout) :: guard
    integer, intent(in) :: target_mode
    logical, intent(in) :: target_echo_disabled
    integer :: apply_status
    character(len=:), allocatable :: apply_message

    call posix_apply_state(guard%fd, guard%captured_state, target_mode, target_echo_disabled, apply_status, apply_message)
    if (apply_status == TERMIOS_POSIX_APPLY_FAILED) then
      call set_guard_error(guard, FGOF_TERMIOS_ERR_APPLY_FAILED, apply_message)
      return
    end if

    guard%active_mode = target_mode
    guard%echo_disabled = target_echo_disabled
    guard%restore_needed = (target_mode /= FGOF_TERMIOS_MODE_NONE) .or. target_echo_disabled
    call clear_guard_error(guard)
  end subroutine apply_guard_state

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
