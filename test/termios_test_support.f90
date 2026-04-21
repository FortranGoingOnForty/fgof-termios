module termios_test_support
  use, intrinsic :: iso_c_binding, only : c_int
  implicit none
  private

  public :: close_fd
  public :: open_test_pipe
  public :: open_test_pty

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
end module termios_test_support
