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

#ifndef CONFIG_H
#define CONFIG_H

//----------------------------------------------------------------------------

#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>

#include "defs.h"

#include <sys/types.h>
#include <regex.h>

//----------------------------------------------------------------------------

struct CS_CONFIG_T {

  // SETTINGS
  bool setting_debug;

  // GPIO
  int gpio_pin_pwrsw;
  int gpio_pin_pg;
  int gpio_pin_chrg;
  int gpio_pin_wifi;
  int gpio_pin_overtemp;

  // INTERVAL
  uint8_t interval_max;
  uint8_t interval_gpio;
  uint8_t interval_serial_fast;
};

//----------------------------------------------------------------------------

extern volatile struct CS_CONFIG_T c;

#endif
