OBJS=main.o \
	config.o \
	manager.o \
  analog_read/analog_read.o \
	gpio/gpio.o \
	gpio_in/gpio_in.o \
	serialport/serialport.o \
	state.o \
	batt_mon/batt_mon.o

BIN=cs-hud

CFLAGS+=-Wall -g -O3 -Icommon $(shell libpng-config --cflags)
LDFLAGS+=-lbcm_host -lm -ldl -ffast-math -lwiringPi $(shell libpng-config --ldflags)

INCLUDES+=-Ianalog_read/ -Igpio/ -Igpio_in/ -Ikeyboard/ -Ishift_in/ -Iserialport/ -Ibatt_mon/

all: $(BIN)

%.o: %.c
	@rm -f $@
	$(CC) $(CFLAGS) $(INCLUDES) -g -c $< -o $@ -Wno-deprecated-declarations

$(BIN): $(OBJS)
	$(CC) -o $@ -Wl,--whole-archive $(OBJS) $(LDFLAGS) -pthread -Wl,--no-whole-archive -rdynamic

clean:
	@rm -f $(OBJS)
	@rm -f $(BIN)
