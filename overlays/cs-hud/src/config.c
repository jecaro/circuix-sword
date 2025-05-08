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

#include "config.h"

//-----------------------------------------------------------------------------

// Default some sensible values
volatile struct CS_CONFIG_T c = {

  // SETTINGS
  .setting_debug = false,

  // GPIO
  .gpio_pin_pwrsw = 37,
  .gpio_pin_pg = 38,
  .gpio_pin_chrg = 36,
  .gpio_pin_wifi = 34,
  .gpio_pin_overtemp = 35,

  // INTERVAL
  .interval_max = 60,
  .interval_gpio = 60,
  .interval_serial_fast = 10,
};

//-----------------------------------------------------------------------------

