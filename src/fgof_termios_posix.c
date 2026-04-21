#define _XOPEN_SOURCE 600

#include <errno.h>
#include <fcntl.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

int fgof_termios_is_tty(int fd) {
    return isatty(fd) ? 1 : 0;
}

size_t fgof_termios_state_size(void) {
    return sizeof(struct termios);
}

static void fgof_termios_make_raw(struct termios *state) {
    state->c_iflag &= (tcflag_t) ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
    state->c_oflag &= (tcflag_t) ~OPOST;
    state->c_cflag &= (tcflag_t) ~(CSIZE | PARENB);
    state->c_cflag |= (tcflag_t) CS8;
    state->c_lflag &= (tcflag_t) ~(ECHO | ECHONL | ICANON | IEXTEN | ISIG);
    state->c_cc[VMIN] = 1;
    state->c_cc[VTIME] = 0;
}

static void fgof_termios_apply_echo_policy(struct termios *state,
                                           const struct termios *original_state,
                                           int mode,
                                           int echo_policy) {
    if (echo_policy == 1) {
        state->c_lflag &= (tcflag_t) ~(ECHO | ECHOE | ECHOK | ECHONL);
        return;
    }

    if (echo_policy == 2) {
        state->c_lflag |= (tcflag_t) ECHO;
        if (original_state->c_lflag & ECHOE) {
            state->c_lflag |= (tcflag_t) ECHOE;
        } else {
            state->c_lflag &= (tcflag_t) ~ECHOE;
        }
        if (original_state->c_lflag & ECHOK) {
            state->c_lflag |= (tcflag_t) ECHOK;
        } else {
            state->c_lflag &= (tcflag_t) ~ECHOK;
        }
        if (original_state->c_lflag & ECHONL) {
            state->c_lflag |= (tcflag_t) ECHONL;
        } else {
            state->c_lflag &= (tcflag_t) ~ECHONL;
        }
        return;
    }

    if (mode == 1) {
        state->c_lflag &= (tcflag_t) ~(ECHO | ECHOE | ECHOK | ECHONL);
        return;
    }

    if (original_state->c_lflag & ECHO) {
        state->c_lflag |= (tcflag_t) ECHO;
    } else {
        state->c_lflag &= (tcflag_t) ~ECHO;
    }
    if (original_state->c_lflag & ECHOE) {
        state->c_lflag |= (tcflag_t) ECHOE;
    } else {
        state->c_lflag &= (tcflag_t) ~ECHOE;
    }
    if (original_state->c_lflag & ECHOK) {
        state->c_lflag |= (tcflag_t) ECHOK;
    } else {
        state->c_lflag &= (tcflag_t) ~ECHOK;
    }
    if (original_state->c_lflag & ECHONL) {
        state->c_lflag |= (tcflag_t) ECHONL;
    } else {
        state->c_lflag &= (tcflag_t) ~ECHONL;
    }
}

static int fgof_termios_load_state(const signed char *buffer,
                                   size_t buffer_len,
                                   struct termios *state,
                                   int *sys_errno) {
    *sys_errno = 0;
    if (buffer == NULL || state == NULL || buffer_len < sizeof(*state)) {
        *sys_errno = EINVAL;
        return -1;
    }

    memcpy(state, buffer, sizeof(*state));
    return 0;
}

int fgof_termios_capture_state(int fd,
                               signed char *buffer,
                               size_t buffer_len,
                               int *sys_errno) {
    struct termios state;

    *sys_errno = 0;
    if (buffer == NULL || buffer_len < sizeof(state)) {
        *sys_errno = EINVAL;
        return -1;
    }

    if (tcgetattr(fd, &state) != 0) {
        *sys_errno = errno;
        return -1;
    }

    memcpy(buffer, &state, sizeof(state));
    return 0;
}

int fgof_termios_apply_state(int fd,
                             const signed char *snapshot,
                             size_t snapshot_len,
                             int mode,
                             int echo_policy,
                             int *sys_errno) {
    struct termios original_state;
    struct termios state;

    if (fgof_termios_load_state(snapshot, snapshot_len, &state, sys_errno) != 0) {
        return -1;
    }
    original_state = state;

    switch (mode) {
    case 1:
        fgof_termios_make_raw(&state);
        break;
    case 2:
        state.c_lflag &= (tcflag_t) ~ICANON;
        state.c_cc[VMIN] = 1;
        state.c_cc[VTIME] = 0;
        break;
    default:
        break;
    }

    fgof_termios_apply_echo_policy(&state, &original_state, mode, echo_policy);

    if (tcsetattr(fd, TCSANOW, &state) != 0) {
        *sys_errno = errno;
        return -1;
    }

    return 0;
}

int fgof_termios_restore_state(int fd,
                               const signed char *snapshot,
                               size_t snapshot_len,
                               int *sys_errno) {
    struct termios state;

    if (fgof_termios_load_state(snapshot, snapshot_len, &state, sys_errno) != 0) {
        return -1;
    }

    if (tcsetattr(fd, TCSANOW, &state) != 0) {
        *sys_errno = errno;
        return -1;
    }

    return 0;
}

int fgof_termios_get_terminal_size(int fd,
                                   int *rows,
                                   int *columns,
                                   int *sys_errno) {
    struct winsize size;

    *rows = 0;
    *columns = 0;
    *sys_errno = 0;

    if (ioctl(fd, TIOCGWINSZ, &size) != 0) {
        *sys_errno = errno;
        return -1;
    }

    *rows = (int) size.ws_row;
    *columns = (int) size.ws_col;
    return 0;
}

int fgof_termios_get_fd_identity(int fd,
                                 long long *device_id,
                                 long long *inode_id,
                                 int *sys_errno) {
    struct stat info;

    *device_id = 0;
    *inode_id = 0;
    *sys_errno = 0;
    if (fstat(fd, &info) != 0) {
        *sys_errno = errno;
        return -1;
    }

    *device_id = (long long) info.st_dev;
    *inode_id = (long long) info.st_ino;
    return 0;
}

int fgof_termios_open_test_pty(int *master_fd, int *slave_fd, int *sys_errno) {
    int master;
    int slave;
    char *slave_name;

    *master_fd = -1;
    *slave_fd = -1;
    *sys_errno = 0;

    master = posix_openpt(O_RDWR | O_NOCTTY);
    if (master < 0) {
      *sys_errno = errno;
      return -1;
    }

    if (grantpt(master) != 0 || unlockpt(master) != 0) {
      *sys_errno = errno;
      close(master);
      return -1;
    }

    slave_name = ptsname(master);
    if (slave_name == NULL) {
      *sys_errno = errno;
      close(master);
      return -1;
    }

    slave = open(slave_name, O_RDWR | O_NOCTTY);
    if (slave < 0) {
      *sys_errno = errno;
      close(master);
      return -1;
    }

    *master_fd = master;
    *slave_fd = slave;
    return 0;
}

int fgof_termios_open_test_pipe(int *read_fd, int *write_fd, int *sys_errno) {
    int pipe_fds[2];

    *read_fd = -1;
    *write_fd = -1;
    *sys_errno = 0;

    if (pipe(pipe_fds) != 0) {
        *sys_errno = errno;
        return -1;
    }

    *read_fd = pipe_fds[0];
    *write_fd = pipe_fds[1];
    return 0;
}

int fgof_termios_close_fd(int fd, int *sys_errno) {
    *sys_errno = 0;
    if (close(fd) != 0) {
        *sys_errno = errno;
        return -1;
    }
    return 0;
}

int fgof_termios_test_seed_defaults(int fd, int *sys_errno) {
    struct termios state;

    *sys_errno = 0;
    if (tcgetattr(fd, &state) != 0) {
        *sys_errno = errno;
        return -1;
    }

    state.c_lflag |= (tcflag_t) (ICANON | ECHO | ECHOE | ECHOK | ISIG | IEXTEN);
    state.c_cc[VMIN] = 1;
    state.c_cc[VTIME] = 0;

    if (tcsetattr(fd, TCSANOW, &state) != 0) {
        *sys_errno = errno;
        return -1;
    }

    return 0;
}

int fgof_termios_test_read_state(int fd,
                                 int *canonical_enabled,
                                 int *echo_enabled,
                                 int *signals_enabled,
                                 int *vmin,
                                 int *vtime,
                                 int *sys_errno) {
    struct termios state;

    *sys_errno = 0;
    if (tcgetattr(fd, &state) != 0) {
        *sys_errno = errno;
        return -1;
    }

    *canonical_enabled = (state.c_lflag & ICANON) ? 1 : 0;
    *echo_enabled = (state.c_lflag & ECHO) ? 1 : 0;
    *signals_enabled = (state.c_lflag & ISIG) ? 1 : 0;
    *vmin = (int) state.c_cc[VMIN];
    *vtime = (int) state.c_cc[VTIME];
    return 0;
}

int fgof_termios_test_set_size(int fd, int rows, int columns, int *sys_errno) {
    struct winsize size;

    *sys_errno = 0;
    if (rows <= 0 || columns <= 0) {
        *sys_errno = EINVAL;
        return -1;
    }

    memset(&size, 0, sizeof(size));
    size.ws_row = (unsigned short) rows;
    size.ws_col = (unsigned short) columns;
    if (ioctl(fd, TIOCSWINSZ, &size) != 0) {
        *sys_errno = errno;
        return -1;
    }

    return 0;
}

int fgof_termios_test_raw_profile_ok(int fd, int *matches, int *sys_errno) {
    struct termios state;

    *matches = 0;
    *sys_errno = 0;
    if (tcgetattr(fd, &state) != 0) {
        *sys_errno = errno;
        return -1;
    }

    if ((state.c_iflag & (IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON)) != 0) {
        return 0;
    }
    if ((state.c_oflag & OPOST) != 0) {
        return 0;
    }
    if ((state.c_lflag & (ECHO | ECHONL | ICANON | ISIG | IEXTEN)) != 0) {
        return 0;
    }
    if ((state.c_cflag & PARENB) != 0) {
        return 0;
    }
    if ((state.c_cflag & CSIZE) != CS8) {
        return 0;
    }
    if (state.c_cc[VMIN] != 1 || state.c_cc[VTIME] != 0) {
        return 0;
    }

    *matches = 1;
    return 0;
}

int fgof_termios_test_dup_fd(int source_fd, int target_fd, int *sys_errno) {
    *sys_errno = 0;
    if (dup2(source_fd, target_fd) < 0) {
        *sys_errno = errno;
        return -1;
    }

    return 0;
}
