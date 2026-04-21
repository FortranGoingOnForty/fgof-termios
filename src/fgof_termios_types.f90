module fgof_termios_types
  use, intrinsic :: iso_c_binding, only : c_long_long, c_signed_char
  implicit none
  private

  public :: FGOF_TERMIOS_ERR_NONE
  public :: FGOF_TERMIOS_ERR_INVALID_FD
  public :: FGOF_TERMIOS_ERR_NOT_A_TTY
  public :: FGOF_TERMIOS_ERR_CAPTURE_FAILED
  public :: FGOF_TERMIOS_ERR_APPLY_FAILED
  public :: FGOF_TERMIOS_ERR_RESTORE_FAILED
  public :: FGOF_TERMIOS_ERR_UNBOUND_GUARD
  public :: FGOF_TERMIOS_MODE_NONE
  public :: FGOF_TERMIOS_MODE_RAW
  public :: FGOF_TERMIOS_MODE_CBREAK
  public :: terminal_size
  public :: termios_guard

  integer, parameter :: FGOF_TERMIOS_ERR_NONE = 0
  integer, parameter :: FGOF_TERMIOS_ERR_INVALID_FD = 1
  integer, parameter :: FGOF_TERMIOS_ERR_NOT_A_TTY = 2
  integer, parameter :: FGOF_TERMIOS_ERR_CAPTURE_FAILED = 3
  integer, parameter :: FGOF_TERMIOS_ERR_APPLY_FAILED = 4
  integer, parameter :: FGOF_TERMIOS_ERR_RESTORE_FAILED = 5
  integer, parameter :: FGOF_TERMIOS_ERR_UNBOUND_GUARD = 6

  integer, parameter :: FGOF_TERMIOS_MODE_NONE = 0
  integer, parameter :: FGOF_TERMIOS_MODE_RAW = 1
  integer, parameter :: FGOF_TERMIOS_MODE_CBREAK = 2

  type :: terminal_size
    integer :: rows = 0
    integer :: columns = 0
    logical :: valid = .false.
  end type terminal_size

  type :: termios_guard
    integer :: fd = -1
    integer :: active_mode = FGOF_TERMIOS_MODE_NONE
    logical :: bound = .false.
    logical :: tty = .false.
    logical :: snapshot_captured = .false.
    logical :: identity_captured = .false.
    logical :: restore_needed = .false.
    logical :: echo_overridden = .false.
    logical :: echo_disabled = .false.
    integer(c_long_long) :: bound_device_id = 0_c_long_long
    integer(c_long_long) :: bound_inode_id = 0_c_long_long
    integer(c_signed_char), allocatable :: captured_state(:)
    integer :: last_error_code = FGOF_TERMIOS_ERR_NONE
    character(len=:), allocatable :: last_error_message
  end type termios_guard
end module fgof_termios_types
