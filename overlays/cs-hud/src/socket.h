#ifndef SOCKET_H
#define SOCKET_H

#include "state.h"

// Write the battery state to a unix socket

bool socket_init();
void socket_unload();
bool socket_process();

#endif

