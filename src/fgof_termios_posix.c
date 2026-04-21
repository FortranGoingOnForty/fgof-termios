#define _XOPEN_SOURCE 600

#include <errno.h>
#include <fcntl.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

int fgof_termios_is_tty(int fd) {
    return isatty(fd) ? 1 : 0;
}

size_t fgof_termios_state_size(void) {
    return sizeof(struct termios);
}

static void fgof_termios_make_raw(struct termios *state) {
    state->c_iflag &= (tcflag_t) ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    state->c_oflag &= (tcflag_t) ~OPOST;
    state->c_cflag |= (tcflag_t) CS8;
    state->c_lflag &= (tcflag_t) ~(ECHO | ICANON | IEXTEN | ISIG);
    state->c_cc[VMIN] = 1;
    state->c_cc[VTIME] = 0;
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
                             int echo_disabled,
                             int *sys_errno) {
    struct termios state;

    if (fgof_termios_load_state(snapshot, snapshot_len, &state, sys_errno) != 0) {
        return -1;
    }

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

    if (echo_disabled) {
        state.c_lflag &= (tcflag_t) ~(ECHO | ECHOE | ECHOK | ECHONL);
    }

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
