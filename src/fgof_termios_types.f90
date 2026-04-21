module fgof_termios_types
  implicit none
  private

  public :: FGOF_TERMIOS_ERR_NONE
  public :: FGOF_TERMIOS_ERR_INVALID_FD
  public :: FGOF_TERMIOS_ERR_UNBOUND_GUARD
  public :: FGOF_TERMIOS_MODE_NONE
  public :: FGOF_TERMIOS_MODE_RAW
  public :: FGOF_TERMIOS_MODE_CBREAK
  public :: terminal_size
  public :: termios_guard

  integer, parameter :: FGOF_TERMIOS_ERR_NONE = 0
  integer, parameter :: FGOF_TERMIOS_ERR_INVALID_FD = 1
  integer, parameter :: FGOF_TERMIOS_ERR_UNBOUND_GUARD = 2

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
    logical :: snapshot_captured = .false.
    logical :: restore_needed = .false.
    logical :: echo_disabled = .false.
    integer :: last_error_code = FGOF_TERMIOS_ERR_NONE
    character(len=:), allocatable :: last_error_message
  end type termios_guard
end module fgof_termios_types
