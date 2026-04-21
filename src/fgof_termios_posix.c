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
