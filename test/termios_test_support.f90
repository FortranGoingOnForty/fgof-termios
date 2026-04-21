module termios_test_support
  use, intrinsic :: iso_c_binding, only : c_int
  implicit none
  private

  public :: close_fd
  public :: expect_state
  public :: open_test_pipe
  public :: open_test_pty
  public :: seed_test_tty_defaults
  public :: set_test_terminal_size

  interface
    integer(c_int) function fgof_termios_open_test_pty_c(master_fd, slave_fd, sys_errno) bind(C, name="fgof_termios_open_test_pty")
      import :: c_int
      integer(c_int), intent(out) :: master_fd
      integer(c_int), intent(out) :: slave_fd
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_open_test_pty_c

    integer(c_int) function fgof_termios_open_test_pipe_c(read_fd, write_fd, sys_errno) bind(C, name="fgof_termios_open_test_pipe")
      import :: c_int
      integer(c_int), intent(out) :: read_fd
      integer(c_int), intent(out) :: write_fd
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_open_test_pipe_c

    integer(c_int) function fgof_termios_close_fd_c(fd, sys_errno) bind(C, name="fgof_termios_close_fd")
      import :: c_int
      integer(c_int), value :: fd
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_close_fd_c

    integer(c_int) function fgof_termios_test_seed_defaults_c(fd, sys_errno) bind(C, name="fgof_termios_test_seed_defaults")
      import :: c_int
      integer(c_int), value :: fd
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_test_seed_defaults_c

    integer(c_int) function fgof_termios_test_read_state_c(fd, canonical_enabled, echo_enabled, signals_enabled, vmin, vtime, sys_errno) bind(C, name="fgof_termios_test_read_state")
      import :: c_int
      integer(c_int), value :: fd
      integer(c_int), intent(out) :: canonical_enabled
      integer(c_int), intent(out) :: echo_enabled
      integer(c_int), intent(out) :: signals_enabled
      integer(c_int), intent(out) :: vmin
      integer(c_int), intent(out) :: vtime
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_test_read_state_c

    integer(c_int) function fgof_termios_test_set_size_c(fd, rows, columns, sys_errno) bind(C, name="fgof_termios_test_set_size")
      import :: c_int
      integer(c_int), value :: fd
      integer(c_int), value :: rows
      integer(c_int), value :: columns
      integer(c_int), intent(out) :: sys_errno
    end function fgof_termios_test_set_size_c
  end interface

contains

  subroutine open_test_pty(master_fd, slave_fd)
    integer, intent(out) :: master_fd
    integer, intent(out) :: slave_fd
    integer(c_int) :: master_fd_c
    integer(c_int) :: slave_fd_c
    integer(c_int) :: sys_errno
    integer(c_int) :: status

    status = fgof_termios_open_test_pty_c(master_fd_c, slave_fd_c, sys_errno)
    if (status /= 0_c_int) then
      error stop "failed to open test pty"
    end if

    master_fd = int(master_fd_c)
    slave_fd = int(slave_fd_c)
  end subroutine open_test_pty

  subroutine open_test_pipe(read_fd, write_fd)
    integer, intent(out) :: read_fd
    integer, intent(out) :: write_fd
    integer(c_int) :: read_fd_c
    integer(c_int) :: write_fd_c
    integer(c_int) :: sys_errno
    integer(c_int) :: status

    status = fgof_termios_open_test_pipe_c(read_fd_c, write_fd_c, sys_errno)
    if (status /= 0_c_int) then
      error stop "failed to open test pipe"
    end if

    read_fd = int(read_fd_c)
    write_fd = int(write_fd_c)
  end subroutine open_test_pipe

  subroutine close_fd(fd)
    integer, intent(inout) :: fd
    integer(c_int) :: sys_errno
    integer(c_int) :: status

    if (fd < 0) return

    status = fgof_termios_close_fd_c(int(fd, c_int), sys_errno)
    if (status /= 0_c_int) then
      error stop "failed to close test fd"
    end if

    fd = -1
  end subroutine close_fd

  subroutine seed_test_tty_defaults(fd)
    integer, intent(in) :: fd
    integer(c_int) :: sys_errno
    integer(c_int) :: status

    status = fgof_termios_test_seed_defaults_c(int(fd, c_int), sys_errno)
    if (status /= 0_c_int) then
      error stop "failed to seed test tty defaults"
    end if
  end subroutine seed_test_tty_defaults

  subroutine expect_state(fd, canonical_enabled, echo_enabled, signals_enabled, vmin, vtime, message)
    integer, intent(in) :: fd
    logical, intent(in) :: canonical_enabled
    logical, intent(in) :: echo_enabled
    logical, intent(in) :: signals_enabled
    integer, intent(in) :: vmin
    integer, intent(in) :: vtime
    character(len=*), intent(in) :: message
    integer(c_int) :: canonical_value
    integer(c_int) :: echo_value
    integer(c_int) :: signals_value
    integer(c_int) :: sys_errno
    integer(c_int) :: vmin_value
    integer(c_int) :: vtime_value
    integer(c_int) :: status

    status = fgof_termios_test_read_state_c(int(fd, c_int), canonical_value, echo_value, signals_value, vmin_value, vtime_value, sys_errno)
    if (status /= 0_c_int) then
      error stop trim(message) // ": failed to read tty state"
    end if

    if ((canonical_value /= 0_c_int) .neqv. canonical_enabled) error stop trim(message) // ": wrong canonical flag"
    if ((echo_value /= 0_c_int) .neqv. echo_enabled) error stop trim(message) // ": wrong echo flag"
    if ((signals_value /= 0_c_int) .neqv. signals_enabled) error stop trim(message) // ": wrong signal flag"
    if (int(vmin_value) /= vmin) error stop trim(message) // ": wrong vmin"
    if (int(vtime_value) /= vtime) error stop trim(message) // ": wrong vtime"
  end subroutine expect_state

  subroutine set_test_terminal_size(fd, rows, columns)
    integer, intent(in) :: fd
    integer, intent(in) :: rows
    integer, intent(in) :: columns
    integer(c_int) :: sys_errno
    integer(c_int) :: status

    status = fgof_termios_test_set_size_c(int(fd, c_int), int(rows, c_int), int(columns, c_int), sys_errno)
    if (status /= 0_c_int) then
      error stop "failed to set test terminal size"
    end if
  end subroutine set_test_terminal_size
end module termios_test_support
