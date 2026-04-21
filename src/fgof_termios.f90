module fgof_termios
  use fgof_termios_types, only : terminal_size, termios_guard
  implicit none
  private

  public :: bind_guard
  public :: request_raw_mode
  public :: request_noecho
  public :: restore_guard
  public :: terminal_size_of

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
    guard%bound = .true.
  end subroutine bind_guard

  subroutine request_raw_mode(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. guard%bound) then
      call bind_guard(guard)
    end if
    guard%raw_requested = .true.
  end subroutine request_raw_mode

  subroutine request_noecho(guard)
    type(termios_guard), intent(inout) :: guard

    if (.not. guard%bound) then
      call bind_guard(guard)
    end if
    guard%noecho_requested = .true.
  end subroutine request_noecho

  subroutine restore_guard(guard)
    type(termios_guard), intent(inout) :: guard

    guard%raw_requested = .false.
    guard%noecho_requested = .false.
  end subroutine restore_guard

  function terminal_size_of(rows, columns) result(size)
    integer, intent(in) :: rows
    integer, intent(in) :: columns
    type(terminal_size) :: size

    size%rows = rows
    size%columns = columns
  end function terminal_size_of
end module fgof_termios
