OBJS=main.o \
	config.o \
	manager.o \
	gpio_in/gpio_in.o \
	serialport/serialport.o \
	socket.o \
	state.o

BIN=cs-hud

CFLAGS+=-Wall -g -O3 -Icommon $(shell libpng-config --cflags)
LDFLAGS+=-lbcm_host -lm -ldl -ffast-math -lwiringPi $(shell libpng-config --ldflags)

all: $(BIN)

%.o: %.c
	@rm -f $@
	$(CC) $(CFLAGS) $(INCLUDES) -g -c $< -o $@ -Wno-deprecated-declarations

$(BIN): $(OBJS)
	$(CC) -o $@ -Wl,--whole-archive $(OBJS) $(LDFLAGS) -pthread -Wl,--no-whole-archive -rdynamic

clean:
	@rm -f $(OBJS)
	@rm -f $(BIN)
