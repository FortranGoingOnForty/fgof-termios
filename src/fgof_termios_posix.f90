module fgof_termios_posix
  use, intrinsic :: iso_c_binding, only : c_int, c_signed_char, c_size_t
  implicit none
  private

  integer, parameter, public :: TERMIOS_POSIX_OK = 0
  integer, parameter, public :: TERMIOS_POSIX_NOT_TTY = 1
  integer, parameter, public :: TERMIOS_POSIX_CAPTURE_FAILED = 2

  public :: posix_capture_state

  interface
    integer(c_int) function fgof_termios_is_tty_c(fd) bind(C, name="fgof_termios_is_tty")
      import :: c_int
      integer(c_int), value :: fd
    end function fgof_termios_is_tty_c

    integer(c_size_t) function fgof_termios_state_size_c() bind(C, name="fgof_termios_state_size")
      import :: c_size_t
    end function fgof_termios_state_size_c

    integer(c_int) function fgof_termios_capture_state_c(fd, buffer, buffer_len, sys_errno) bind(C, name="fgof_termios_capture_state")
      import :: c_int, c_signed_char, c_size_t
      integer(c_int), value :: fd
      integer(c_signed_char), intent(out) :: buffer(*)
      integer(c_size_t), value :: buffer_len
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_capture_state_c
  end interface

contains

  subroutine posix_capture_state(fd, state_bytes, tty_ready, status_code, status_message)
    integer, intent(in) :: fd
    integer(c_signed_char), allocatable, intent(out) :: state_bytes(:)
    logical, intent(out) :: tty_ready
    integer, intent(out) :: status_code
    character(len=:), allocatable, intent(out) :: status_message
    integer(c_int) :: capture_status
    integer(c_int) :: sys_errno
    integer(c_size_t) :: state_len

    tty_ready = .false.
    status_code = TERMIOS_POSIX_OK
    status_message = ""
    allocate(state_bytes(0))

    if (fgof_termios_is_tty_c(int(fd, c_int)) == 0_c_int) then
      status_code = TERMIOS_POSIX_NOT_TTY
      status_message = "fd is not a tty"
      return
    end if
    tty_ready = .true.

    state_len = fgof_termios_state_size_c()
    if (state_len == 0_c_size_t) then
      status_code = TERMIOS_POSIX_CAPTURE_FAILED
      status_message = "terminal state capture failed (empty state size)"
      return
    end if

    deallocate(state_bytes)
    allocate(state_bytes(int(state_len)))
    sys_errno = 0_c_int
    capture_status = fgof_termios_capture_state_c(int(fd, c_int), state_bytes, state_len, sys_errno)
    if (capture_status /= 0_c_int) then
      deallocate(state_bytes)
      allocate(state_bytes(0))
      status_code = TERMIOS_POSIX_CAPTURE_FAILED
      status_message = errno_message("terminal state capture failed", int(sys_errno))
      return
    end if
  end subroutine posix_capture_state

  function errno_message(prefix, errnum) result(message)
    character(len=*), intent(in) :: prefix
    integer, intent(in) :: errnum
    character(len=:), allocatable :: message
    character(len=32) :: code_text

    write(code_text, '(I0)') errnum
    message = trim(prefix) // " (errno=" // trim(code_text) // ")"
  end function errno_message
end module fgof_termios_posix
