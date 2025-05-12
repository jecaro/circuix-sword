#include "socket.h"

#include <sys/socket.h>
#include <sys/un.h>

#define SOCKET_PATH "/tmp/cs-hud.sock"

#pragma pack(push, 1)
struct Payload
{
  bool plugged;
  bool charging;
  uint8_t percent;
};
#pragma pack(pop)

bool socket_init() {
  unlink(SOCKET_PATH);

  cs_state.socket_fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (cs_state.socket_fd == -1) {
    printf("[!] ERROR: Failed to create socket\n");
    goto error;
  }
  // Set the socket to non-blocking mode
  int flags = fcntl(cs_state.socket_fd, F_GETFL, 0);
  fcntl(cs_state.socket_fd, F_SETFL, flags | O_NONBLOCK);

  struct sockaddr_un addr = {0};
  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

  if (bind(cs_state.socket_fd, (struct sockaddr *) &addr, sizeof(struct sockaddr_un)) == -1) {
    printf("[!] ERROR: Failed to bind socket\n");
    goto error;
  }

  // 5 is the maximum number of pending connections
  if (listen(cs_state.socket_fd, 5) == -1) {
    printf("[!] ERROR: Failed to listen on socket\n");
    goto error;
  }

  printf("[*] Server listening on %s\n", SOCKET_PATH);

  return true;

error:
  close(cs_state.socket_fd);
  cs_state.socket_fd = -1;
  return false;
}

void socket_unload() {
  if (cs_state.socket_fd == -1) {
    return;
  }
  close(cs_state.socket_fd);
  unlink(SOCKET_PATH);
}

bool socket_process() {
  if (cs_state.socket_fd == -1) {
    return false;
  }

  int client_fd = accept(cs_state.socket_fd, NULL, NULL);

  struct Payload payload = {
    .plugged = cs_state.pg_state,
    .charging = cs_state.chrg_state,
    .percent = state_batt_get_charge(),
  };

  if (cs_state.debug_state) {
    printf("Sending payload: plugged=%d, charging=%d, percent=%d\n",
        payload.plugged, payload.charging, payload.percent);
  }
  ssize_t n = write(client_fd, &payload, sizeof(payload));
  (void)n;

  close(client_fd);

  return true;
}

