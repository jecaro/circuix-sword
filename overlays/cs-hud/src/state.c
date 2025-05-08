//-----------------------------------------------------------------------------
/*
 * The GPL v3 License
 *
 * Kite's Circuit Sword
 * Copyright (C) 2017 Giles Burgess (Kite's Item Shop)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

 //----------------------------------------------------------------------------

#include "state.h"

#include <linux/input.h>

//-----------------------------------------------------------------------------

// Default some sensible values
volatile struct CS_STATE_T cs_state = {
  .state            = STATE_NONE,
  .power_switch_on  = true,
  .mode_button_on   = false,

  .wifi_state       = true,

  .batt_voltage     = 0.01,
  .batt_voltage_min = 3.20,
  .batt_voltage_low = 3.25,
  .batt_voltage_max = 4.00,

  .brightness  = -1,
  .volume      = -1,

  .temperature_over = true,
  .temperature = 0.0,
  .temperature_threshold = 60.0,
  .temperature_holdoff = 55.0,
  // .temperature_threshold = 40.0,
  // .temperature_holdoff = 35.0,
};

uint8_t qPos = 0;
uint8_t qCount = 0;

struct CS_SERIAL_T q[SERIAL_Q_LENGTH];

//-----------------------------------------------------------------------------

uint16_t convertFrom8To16(uint8_t dataFirst, uint8_t dataSecond)
{
  uint16_t dataBoth = 0x0000;

  dataBoth = dataFirst;
  dataBoth = dataBoth << 8;
  dataBoth |= dataSecond;
  return dataBoth;
}

//-----------------------------------------------------------------------------

void add_to_serial_queue(uint8_t cmd, uint8_t data)
{
  if (c.setting_serial == ENABLED) {
    if (qCount < SERIAL_Q_LENGTH - 1) {
      // Determine new pos
      uint8_t new_qPos = qPos + qCount;
      if (new_qPos >= SERIAL_Q_LENGTH) {
        new_qPos -= SERIAL_Q_LENGTH;
      }

      // Create the packet
      struct CS_SERIAL_T p = {
        .cmd = cmd,
        .data = data,
      };

      // Add to queue
      q[new_qPos] = p;
      qCount++;
      // printf("[i] ADDED [%i][%i] at [%i]\n", p.cmd, p.data, new_qPos);
    } else {
      printf("[#] WARNING: Serial queue is full, cannot add [%i][%i] to it\n", cmd, data);
    }
  }
}

//-----------------------------------------------------------------------------

int8_t get_volume()
{
  int strength = 20;
  int i;
  FILE *fd;

  // Open wifi file
  fd = popen("amixer sget PCM", "r");
  if (fd == NULL) {
    printf("[!] ERROR: Failed to read amixer volume\n");
    return -1;
  }

  int len = 32;
  char buf[len];

  // skip first five lines
  for (i = 0; i < 5; i++) {
    char * unused = fgets(buf, len, fd);
    (void) unused;
  }

  char s_string[] = {'['};
  uint16_t s_pos = 0;
  uint16_t s_hit = sizeof(s_string)/sizeof(s_string[0]);

  bool searching = true;
  while (searching) {
    // For each line of output
    if (fgets(buf, len, fd)) {

      bool correct_line = false;
      uint8_t num_len = 0;
      uint8_t num_count = 0;
      char result[10];

      for (i = 0; i < len; i++) {
        // printf("[%c]", buf[i]);

        if (correct_line) {

          // If is a number
          if (buf[i] >= '0' && buf[i] <= '9') {

            // Add to output
            result[num_len] = buf[i];
            num_len++;

          // else if percentage
          } else if (buf[i] == '%') {

              num_count++;

              // Add term char
              result[num_len] = '\0';

              // convert output to number
              sscanf(result, "%d", &strength);

              // end the search
              searching = false;
              i = len;

          } else {
            // reset number
            num_len = 0;
          }

        } else {

          if (buf[i] == s_string[s_pos]) {
            s_pos++;
          } else {
            // Reset search
            if (s_pos > 0) {
              s_pos = 0;
            }
          }
          // This line is right with wlan0?
          if (s_pos == s_hit) {
            correct_line = true;
          }
        }
      }
    } else {
      searching = false;
    }
  }

  // We're done with the file
  pclose(fd);

  if (strength > 100) {
    return 100;
  } else if (strength < 0) {
    return 0;
  } else {
    return (strength & 0xFF);
  }
}

void state_do_poweroff()
{
  FILE *fd;

  // Perform safe action first
  fd = popen("cs_shutdown.sh", "r");
  if (fd == NULL) {
    printf("[!] ERROR: Failed to run cs_shutdown.sh before power down\n");
  } else {
    printf("[*] Running cs_shutdown.sh..\n");

    char buf[256];
    while (fgets(buf, sizeof(buf)-1, fd) != NULL) {
      printf("[d] %s", buf);
    }

    pclose(fd);

    exit(0);
  }
}

//-----------------------------------------------------------------------------

bool state_init()
{
  printf("[*] state_init..\n");

  // Start GPIO library
  if (wiringPiSetupGpio() == -1) {
    return 1;
  }

  // GPIOs
  if (c.gpio_pin_overtemp > -1) {
    pinMode(c.gpio_pin_overtemp, OUTPUT);
    digitalWrite(c.gpio_pin_overtemp, 0);
  }

  if (c.gpio_pin_wifi > -1) {
    pinMode(c.gpio_pin_wifi, OUTPUT);
    digitalWrite(c.gpio_pin_wifi, 1);
  }

  // SERIAL
  if (c.setting_serial == ENABLED) {
    serial_init(SERIAL_DEVICE);
    serial_clear();
  }

  // INPUT METHOD
  if (c.setting_input == INPUT_GPIO) {

    int gpio_in_pins_counter = 0;
    int gpio_in_pins[16] = { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };

    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_up     > -1 ? c.gpio_in_up     : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_down   > -1 ? c.gpio_in_down   : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_left   > -1 ? c.gpio_in_left   : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_right  > -1 ? c.gpio_in_right  : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_start  > -1 ? c.gpio_in_start  : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_select > -1 ? c.gpio_in_select : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_a      > -1 ? c.gpio_in_a      : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_b      > -1 ? c.gpio_in_b      : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_x      > -1 ? c.gpio_in_x      : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_y      > -1 ? c.gpio_in_y      : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_c1     > -1 ? c.gpio_in_c1     : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_c2     > -1 ? c.gpio_in_c2     : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_l1     > -1 ? c.gpio_in_l1     : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_l2     > -1 ? c.gpio_in_l2     : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_r1     > -1 ? c.gpio_in_r1     : -1;
    gpio_in_pins[gpio_in_pins_counter++] =  c.gpio_in_r2     > -1 ? c.gpio_in_r2     : -1;

    gpio_in_init(gpio_in_pins, 16);
  }

  // VOLUME
  if (c.setting_vol == ENABLED) {
    cs_state.volume = get_volume();
    printf("[i] Found system volume already at %d\n", cs_state.volume);
  }

  // CONF
  cs_state.gamepad.up.value     = KEY_UP;
  cs_state.gamepad.down.value   = KEY_DOWN;
  cs_state.gamepad.left.value   = KEY_LEFT;
  cs_state.gamepad.right.value  = KEY_RIGHT;
  cs_state.gamepad.start.value  = KEY_ENTER;
  cs_state.gamepad.select.value = KEY_ESC;
  cs_state.gamepad.a.value      = KEY_Z;
  cs_state.gamepad.b.value      = KEY_X;
  cs_state.gamepad.x.value      = KEY_A;
  cs_state.gamepad.y.value      = KEY_S;
  cs_state.gamepad.c1.value     = KEY_Q;
  cs_state.gamepad.c2.value     = KEY_W;
  cs_state.gamepad.l1.value     = KEY_1;
  cs_state.gamepad.l2.value     = KEY_2;
  cs_state.gamepad.r1.value     = KEY_3;
  cs_state.gamepad.r2.value     = KEY_4;
  cs_state.gamepad.jup.value    = KEY_I;
  cs_state.gamepad.jdown.value  = KEY_K;
  cs_state.gamepad.jleft.value  = KEY_J;
  cs_state.gamepad.jright.value = KEY_L;

  return 0;
}

//-----------------------------------------------------------------------------

void process_temperature()
{
  double temp;

  // Read temperature
  FILE *fd;
  fd = fopen("/sys/class/thermal/thermal_zone0/temp", "r");
  if (fd == NULL) {
    printf("[!] ERROR: Failed to read CPU temperature\n");
    return;
  }

  if (fscanf(fd, "%lf", &temp) != 1) {
    printf("[!] ERROR: Failed to read CPU temperature\n");
  }
  fclose(fd);

  if (temp > 0) {
    temp /= 1000;
  }
  // printf("[d] The temperature is %f C.\n", temp);

  if (temp > 0 && temp < 160) {
    cs_state.temperature = temp;
  } else {
    printf("[!] ERROR: CPU temperature not a good number: %f\n", temp);
  }

  // Fan enable
  if (cs_state.temperature > cs_state.temperature_threshold) {
    if (!cs_state.temperature_over) {
      if (c.gpio_pin_overtemp > -1) {
        printf("[d] FAN ON\n");
        digitalWrite(c.gpio_pin_overtemp, 0);
      }
      cs_state.temperature_over = true;
    }
  } else {
    if (cs_state.temperature_over) {
      if (cs_state.temperature < cs_state.temperature_holdoff) {
        if (c.gpio_pin_overtemp > -1) {
          printf("[d] FAN OFF\n");
          digitalWrite(c.gpio_pin_overtemp, 1);
        }
        cs_state.temperature_over = false;
      }
    }
  }
}

void process_volume()
{
  // Actions:
  //  System volume level

  static int volume_last = -1;

  if (cs_state.volume != volume_last) {
    if (cs_state.volume >= 0 && cs_state.volume <= 100) {

      // Build command string
      char cmd[32];
      snprintf(cmd, sizeof(cmd), "amixer sset PCM %i%%", cs_state.volume);

      // Apply the volume
      FILE *fd;
      fd = popen(cmd, "r");
      if (fd == NULL) {
        printf("[!] ERROR: Failed to set volume with amixer\n");
      } else {
        printf("[*] Setting volume to [%i]..\n", cs_state.volume);
        // usleep(1000); //1ms
      }
      pclose(fd);

      volume_last = cs_state.volume;
    }
  }
}

//-----------------------------------------------------------------------------

void state_request_keys()
{
  // Request keys in a special case (menu?)
  add_to_serial_queue(SERIAL_CMD_GET_BTN_LAST, 0);
}

//-----------------------------------------------------------------------------

void state_process_aux_gpio()
{
  // Read any configured GPIOs
  if (c.gpio_pin_pwrsw > -1) {
    if (c.setting_pwrsw_menu) {
      cs_state.mode_button_on = !digitalRead(c.gpio_pin_pwrsw);
    } else {
      cs_state.power_switch_on = digitalRead(c.gpio_pin_pwrsw);
    }
  }
  if (c.gpio_pin_chrg > -1) {
    cs_state.chrg_state = digitalRead(c.gpio_pin_chrg);
  }
  if (c.gpio_pin_pg > -1) {
    cs_state.pg_state = digitalRead(c.gpio_pin_pg);
  }
  if (c.gpio_pin_mode > -1) {
    cs_state.mode_button_on = !digitalRead(c.gpio_pin_mode);
  }

  // Process power (good a place as any)
  if (c.setting_shutdown == ENABLED) {
    if (!cs_state.power_switch_on) {
      // Power off
      // do_poweroff();
      cs_state.shutdown_state = 1;
    }
  }
}

void state_process_slow_serial()
{
  if (c.setting_input == INPUT_SERIAL) {
    add_to_serial_queue(SERIAL_CMD_GET_VOLT, 0);
    add_to_serial_queue(SERIAL_CMD_GET_BL, 0);
  }
}

void state_process_fast_serial()
{
  if (c.setting_input == INPUT_SERIAL) {
    add_to_serial_queue(SERIAL_CMD_GET_VOL, 0);
    add_to_serial_queue(SERIAL_CMD_GET_STATUS, 0);

    if (cs_state.state == STATE_OSK || cs_state.state == STATE_MENU) {
      add_to_serial_queue(SERIAL_CMD_GET_BTN_LAST, 0);
    }
  }
}

//-----------------------------------------------------------------------------

void state_process_keys()
{
  // Input methods
  if (c.setting_input == INPUT_GPIO) {
    // GPIO input

    // Read 32bits
    uint32_t res = gpio_in_state();
    // printf("%#06x\n", res);

    // Get keys
    cs_state.gamepad.up.pressed     = (res & 0b000000000000000000000001);
    cs_state.gamepad.down.pressed   = (res & 0b000000000000000000000010);
    cs_state.gamepad.left.pressed   = (res & 0b000000000000000000000100);
    cs_state.gamepad.right.pressed  = (res & 0b000000000000000000001000);
    cs_state.gamepad.start.pressed  = (res & 0b000000000000000000010000);
    cs_state.gamepad.select.pressed = (res & 0b000000000000000000100000);
    cs_state.gamepad.a.pressed      = (res & 0b000000000000000001000000);
    cs_state.gamepad.b.pressed      = (res & 0b000000000000000010000000);
    cs_state.gamepad.x.pressed      = (res & 0b000000000000000100000000);
    cs_state.gamepad.y.pressed      = (res & 0b000000000000001000000000);
    cs_state.gamepad.c1.pressed     = (res & 0b000000000000010000000000);
    cs_state.gamepad.c2.pressed     = (res & 0b000000000000100000000000);
    cs_state.gamepad.l1.pressed     = (res & 0b000000000001000000000000);
    cs_state.gamepad.r1.pressed     = (res & 0b000000000010000000000000);
    cs_state.gamepad.l2.pressed     = (res & 0b000000000100000000000000);
    cs_state.gamepad.r2.pressed     = (res & 0b000000001000000000000000);
  }
}

//-----------------------------------------------------------------------------

void state_process_serial()
{
  // Process anything on the serial queue
  if (qCount > 0) {
    // printf("[d] Processing serial cmd [%i][%i] qPos:%i qCount:%i\n", q[qPos].cmd, q[qPos].data, qPos, qCount);
    char rx_buffer[32];
    char tx_buffer[8];

    // VOLTAGE
    if (q[qPos].cmd == SERIAL_CMD_GET_VOLT) {

      // serial_clear();
      serial_send(&q[qPos].cmd, 1);
      int ret = serial_receive_bytes(rx_buffer, 2, 100);

      if (ret == 2) {
        uint16_t v = convertFrom8To16(rx_buffer[1], rx_buffer[0]);
        if (v > 1023) {
          v = 1023;
        }
        v = (uint16_t)((( (float)v * BATT_VOLTSCALE * BATT_DACRES + ( BATT_DACMAX * 5 ) ) / (( BATT_DACRES * BATT_RESDIVVAL ) / BATT_RESDIVMUL)));
        if (v > 550) {
          v = 550;
        }

        if (v > 0) {
          cs_state.batt_voltage = (double)(v/100.0);
        } else {
          cs_state.batt_voltage = 0.1;
        }

      } else {
        printf("[!] Unexpected bytes returned for %c: %i\n", q[qPos].cmd, ret);
      }

    // BACKLIGHT
    } else if (q[qPos].cmd == SERIAL_CMD_GET_BL) {

      // serial_clear();
      serial_send(&q[qPos].cmd, 1);
      int ret = serial_receive_bytes(rx_buffer, 1, 100);

      if (ret == 1) {
        uint8_t bl = rx_buffer[0];
        if (bl > 100) {
          bl = 100;
        }
        cs_state.brightness = bl;

      } else {
        printf("[!] Unexpected bytes returned for %c: %i\n", q[qPos].cmd, ret);
      }

    // GET VOLUME
    } else if (q[qPos].cmd == SERIAL_CMD_GET_VOL) {

      // serial_clear();
      serial_send(&q[qPos].cmd, 1);
      int ret = serial_receive_bytes(rx_buffer, 1, 100);

      if (ret == 1) {
        uint8_t vol = rx_buffer[0];
        if (vol > 100) {
          vol = 100;
        }
        cs_state.volume = vol;

        // Process the volume RIGHT NOW (instant feedback)
        process_volume();

      } else {
        printf("[!] Unexpected bytes returned for %c: %i\n", q[qPos].cmd, ret);
      }

    // STATUS (b[][][DPAD][AVOL][INFO][AUD][WIFI][MODE])
    } else if (q[qPos].cmd == SERIAL_CMD_GET_STATUS) {

      // serial_clear();
      serial_send(&q[qPos].cmd, 1);
      int ret = serial_receive_bytes(rx_buffer, 1, 100);

      if (ret == 1) {
        uint8_t dat = rx_buffer[0];

        cs_state.mode_button_on = dat & (1 << 0);
        cs_state.wifi_state     = dat & (1 << 1);
        cs_state.mute_state   = !(dat & (1 << 2));
        cs_state.debug_state    = dat & (1 << 3);
        cs_state.avol_state     = dat & (1 << 4);
        cs_state.dpad_btns_state= dat & (1 << 5);

      } else {
        printf("[!] Unexpected bytes returned for %c: %i\n", q[qPos].cmd, ret);
      }

    // BUTTON RESET
    } else if (q[qPos].cmd == SERIAL_CMD_RESET_BTN_LAST) {

      // serial_clear();
      serial_send(&q[qPos].cmd, 1);
      int ret = serial_receive_bytes(rx_buffer, 2, 100);

      if (ret != 2) {
        printf("[!] Unexpected bytes returned for %c: %i\n", q[qPos].cmd, ret);
      }

    // BUTTON LAST
    } else if (q[qPos].cmd == SERIAL_CMD_GET_BTN_LAST) {

      // serial_clear();
      serial_send(&q[qPos].cmd, 1);
      int ret = serial_receive_bytes(rx_buffer, 2, 100);

      if (ret == 2) {
        cs_state.gamepad.up.pressed     = rx_buffer[0] & (1 << 0);
        cs_state.gamepad.down.pressed   = rx_buffer[0] & (1 << 1);
        cs_state.gamepad.left.pressed   = rx_buffer[0] & (1 << 2);
        cs_state.gamepad.right.pressed  = rx_buffer[0] & (1 << 3);
        cs_state.gamepad.a.pressed      = rx_buffer[0] & (1 << 4);
        cs_state.gamepad.b.pressed      = rx_buffer[0] & (1 << 5);
        cs_state.gamepad.x.pressed      = rx_buffer[0] & (1 << 6);
        cs_state.gamepad.y.pressed      = rx_buffer[0] & (1 << 7);

        cs_state.gamepad.start.pressed  = rx_buffer[1] & (1 << 0);
        cs_state.gamepad.select.pressed = rx_buffer[1] & (1 << 1);
        cs_state.gamepad.l1.pressed     = rx_buffer[1] & (1 << 2);
        cs_state.gamepad.l2.pressed     = rx_buffer[1] & (1 << 3);
        cs_state.gamepad.r1.pressed     = rx_buffer[1] & (1 << 4);
        cs_state.gamepad.r2.pressed     = rx_buffer[1] & (1 << 5);
        cs_state.gamepad.c1.pressed     = rx_buffer[1] & (1 << 6);
        cs_state.gamepad.c2.pressed     = rx_buffer[1] & (1 << 7);

      } else {
        printf("[!] Unexpected bytes returned for %c: %i\n", q[qPos].cmd, ret);
      }

    // SET VOLUME
    } else if (q[qPos].cmd == SERIAL_CMD_SET_VOL) {

      // serial_clear();
      tx_buffer[0] = q[qPos].cmd;
      tx_buffer[1] = q[qPos].data;
      serial_send(tx_buffer, 2);
      int ret = serial_receive_bytes(rx_buffer, 2, 100);

      if (ret != 2) {
        printf("[!] Unexpected bytes returned for %c: %i\n", q[qPos].cmd, ret);
      }

    // SET WIFI
    } else if (q[qPos].cmd == SERIAL_CMD_SET_WIFI) {

      // serial_clear();
      tx_buffer[0] = q[qPos].cmd;
      if (q[qPos].data == 0) {
        tx_buffer[1] = '0';
      } else {
        tx_buffer[1] = '1';
      }
      serial_send(tx_buffer, 2);
      int ret = serial_receive_bytes(rx_buffer, 2, 100);

      if (ret != 2) {
        printf("[!] Unexpected bytes returned for %c: %i\n", q[qPos].cmd, ret);
      }

    // UNKNOWN
    } else {
      printf("[!] Unsupported serial command %i\n", q[qPos].cmd);
    }

    qPos++;
    if (qPos == SERIAL_Q_LENGTH) {
      qPos = 0;
    }
    qCount--;

  }
}

void state_process_system()
{
  // Precess system bits
  process_temperature();
  process_volume();
}

void state_process_state()
{
  // Determine what should currently be displayed
  if (cs_state.mode_button_on) {
    cs_state.state = STATE_MODE;

  } else if (cs_state.debug_state) {
    cs_state.state = STATE_OSK;

  } else if (cs_state.state != STATE_MENU) {
    cs_state.state = STATE_NONE;

  } else {
    printf("[!] Invalid display state: %i", cs_state.state);
    cs_state.state = STATE_NONE;
  }
  // printf("[d] STATE = %i\n", cs_state.state);

}

//-----------------------------------------------------------------------------

void state_unload()
{
  printf("[*] state_unload..\n");

  if (c.setting_serial == ENABLED) {
    serial_unload();
  }
}
