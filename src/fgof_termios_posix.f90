module fgof_termios_posix
  use, intrinsic :: iso_c_binding, only : c_int, c_long_long, c_signed_char, c_size_t
  implicit none
  private

  integer, parameter, public :: TERMIOS_POSIX_OK = 0
  integer, parameter, public :: TERMIOS_POSIX_NOT_TTY = 1
  integer, parameter, public :: TERMIOS_POSIX_CAPTURE_FAILED = 2
  integer, parameter, public :: TERMIOS_POSIX_APPLY_FAILED = 3
  integer, parameter, public :: TERMIOS_POSIX_RESTORE_FAILED = 4
  integer, parameter, public :: TERMIOS_POSIX_SIZE_FAILED = 5

  public :: posix_apply_state
  public :: posix_capture_state
  public :: posix_get_fd_identity
  public :: posix_get_terminal_size
  public :: posix_restore_state

  interface
    integer(c_int) function fgof_termios_is_tty_c(fd) bind(C, name="fgof_termios_is_tty")
      import :: c_int
      integer(c_int), value :: fd
    end function fgof_termios_is_tty_c

    integer(c_size_t) function fgof_termios_state_size_c() bind(C, name="fgof_termios_state_size")
      import :: c_size_t
    end function fgof_termios_state_size_c

    integer(c_int) function fgof_termios_capture_state_c( &
        fd, buffer, buffer_len, sys_errno) bind(C, name="fgof_termios_capture_state")
      import :: c_int, c_signed_char, c_size_t
      integer(c_int), value :: fd
      integer(c_signed_char), intent(out) :: buffer(*)
      integer(c_size_t), value :: buffer_len
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_capture_state_c

    integer(c_int) function fgof_termios_apply_state_c( &
        fd, snapshot, snapshot_len, mode, echo_policy, sys_errno) bind(C, name="fgof_termios_apply_state")
      import :: c_int, c_signed_char, c_size_t
      integer(c_int), value :: fd
      integer(c_signed_char), intent(in) :: snapshot(*)
      integer(c_size_t), value :: snapshot_len
      integer(c_int), value :: mode
      integer(c_int), value :: echo_policy
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_apply_state_c

    integer(c_int) function fgof_termios_restore_state_c( &
        fd, snapshot, snapshot_len, sys_errno) bind(C, name="fgof_termios_restore_state")
      import :: c_int, c_signed_char, c_size_t
      integer(c_int), value :: fd
      integer(c_signed_char), intent(in) :: snapshot(*)
      integer(c_size_t), value :: snapshot_len
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_restore_state_c

    integer(c_int) function fgof_termios_get_terminal_size_c( &
        fd, rows, columns, sys_errno) bind(C, name="fgof_termios_get_terminal_size")
      import :: c_int
      integer(c_int), value :: fd
      integer(c_int), intent(out) :: rows
      integer(c_int), intent(out) :: columns
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_get_terminal_size_c

    integer(c_int) function fgof_termios_get_fd_identity_c( &
        fd, device_id, inode_id, sys_errno) bind(C, name="fgof_termios_get_fd_identity")
      import :: c_int, c_long_long
      integer(c_int), value :: fd
      integer(c_long_long), intent(out) :: device_id
      integer(c_long_long), intent(out) :: inode_id
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_get_fd_identity_c
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

  subroutine posix_apply_state(fd, state_bytes, mode, echo_policy, status_code, status_message)
    integer, intent(in) :: fd
    integer(c_signed_char), intent(in) :: state_bytes(:)
    integer, intent(in) :: mode
    integer, intent(in) :: echo_policy
    integer, intent(out) :: status_code
    character(len=:), allocatable, intent(out) :: status_message
    integer(c_int) :: apply_status
    integer(c_int) :: sys_errno

    status_code = TERMIOS_POSIX_OK
    status_message = ""
    sys_errno = 0_c_int

    apply_status = fgof_termios_apply_state_c( &
      int(fd, c_int), &
      state_bytes, &
      int(size(state_bytes), c_size_t), &
      int(mode, c_int), &
      int(echo_policy, c_int), &
      sys_errno &
    )
    if (apply_status /= 0_c_int) then
      status_code = TERMIOS_POSIX_APPLY_FAILED
      status_message = errno_message("terminal mode apply failed", int(sys_errno))
    end if
  end subroutine posix_apply_state

  subroutine posix_restore_state(fd, state_bytes, status_code, status_message)
    integer, intent(in) :: fd
    integer(c_signed_char), intent(in) :: state_bytes(:)
    integer, intent(out) :: status_code
    character(len=:), allocatable, intent(out) :: status_message
    integer(c_int) :: restore_status
    integer(c_int) :: sys_errno

    status_code = TERMIOS_POSIX_OK
    status_message = ""
    sys_errno = 0_c_int

    restore_status = fgof_termios_restore_state_c( &
      int(fd, c_int), &
      state_bytes, &
      int(size(state_bytes), c_size_t), &
      sys_errno &
    )
    if (restore_status /= 0_c_int) then
      status_code = TERMIOS_POSIX_RESTORE_FAILED
      status_message = errno_message("terminal state restore failed", int(sys_errno))
    end if
  end subroutine posix_restore_state

  subroutine posix_get_terminal_size(fd, rows, columns, tty_ready, status_code, status_message)
    integer, intent(in) :: fd
    integer, intent(out) :: rows
    integer, intent(out) :: columns
    logical, intent(out) :: tty_ready
    integer, intent(out) :: status_code
    character(len=:), allocatable, intent(out) :: status_message
    integer(c_int) :: query_status
    integer(c_int) :: sys_errno
    integer(c_int) :: rows_c
    integer(c_int) :: columns_c

    rows = 0
    columns = 0
    tty_ready = .false.
    status_code = TERMIOS_POSIX_OK
    status_message = ""

    if (fgof_termios_is_tty_c(int(fd, c_int)) == 0_c_int) then
      status_code = TERMIOS_POSIX_NOT_TTY
      status_message = "fd is not a tty"
      return
    end if
    tty_ready = .true.

    sys_errno = 0_c_int
    rows_c = 0_c_int
    columns_c = 0_c_int
    query_status = fgof_termios_get_terminal_size_c(int(fd, c_int), rows_c, columns_c, sys_errno)
    if (query_status /= 0_c_int) then
      status_code = TERMIOS_POSIX_SIZE_FAILED
      status_message = errno_message("terminal size query failed", int(sys_errno))
      return
    end if

    rows = int(rows_c)
    columns = int(columns_c)
  end subroutine posix_get_terminal_size

  subroutine posix_get_fd_identity(fd, device_id, inode_id, status_code, status_message)
    integer, intent(in) :: fd
    integer(c_long_long), intent(out) :: device_id
    integer(c_long_long), intent(out) :: inode_id
    integer, intent(out) :: status_code
    character(len=:), allocatable, intent(out) :: status_message
    integer(c_int) :: identity_status
    integer(c_int) :: sys_errno

    device_id = 0_c_long_long
    inode_id = 0_c_long_long
    status_code = TERMIOS_POSIX_OK
    status_message = ""
    sys_errno = 0_c_int

    identity_status = fgof_termios_get_fd_identity_c(int(fd, c_int), device_id, inode_id, sys_errno)
    if (identity_status /= 0_c_int) then
      status_code = TERMIOS_POSIX_CAPTURE_FAILED
      status_message = errno_message("terminal identity capture failed", int(sys_errno))
    end if
  end subroutine posix_get_fd_identity

  function errno_message(prefix, errnum) result(message)
    character(len=*), intent(in) :: prefix
    integer, intent(in) :: errnum
    character(len=:), allocatable :: message
    character(len=32) :: code_text

    write(code_text, '(I0)') errnum
    message = trim(prefix) // " (errno=" // trim(code_text) // ")"
  end function errno_message
end module fgof_termios_posix
