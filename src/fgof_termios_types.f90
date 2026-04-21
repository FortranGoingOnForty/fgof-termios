module fgof_termios_types
  implicit none
  private

  public :: terminal_size
  public :: termios_guard

  type :: terminal_size
    integer :: rows = 0
    integer :: columns = 0
  end type terminal_size

  type :: termios_guard
    integer :: fd = 0
    logical :: bound = .false.
    logical :: raw_requested = .false.
    logical :: noecho_requested = .false.
  end type termios_guard
end module fgof_termios_types
