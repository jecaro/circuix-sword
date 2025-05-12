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

#include "manager.h"

//-----------------------------------------------------------------------------
// PRIVATE VARIABLES
static uint8_t tick = 0;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// METHODS

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

bool manager_process()
{
  // SERIAL FAST: add get vol and status commands to to the queue
  if (tick % c.interval_serial_fast == 0) {
    state_process_fast_serial();
  }

  // SERIAL SLOW: add get volt and bl commands to the queue
  if (tick % c.interval_gpio == 0) {
    state_process_slow_serial();
  }

  // Send all the commands, read the responses and update the state
  state_process_serial();

  if (tick % c.interval_serial_fast == 0) {
    state_process_volume();
  }

  if (tick % c.interval_gpio == 0) {
    // Read GPIO
    state_process_aux_gpio();
    state_process_temperature();
  }

  socket_process();

  // Increment tick
  tick++;
  if (tick >= c.interval_max) {
    tick = 0;

    if (c.setting_debug) {
      printf("[d] power: %i\n", cs_state.power_switch_on);
      printf("[d] chrg:  %i\n", cs_state.chrg_state);
      printf("[d] pg:    %i\n", cs_state.pg_state);
      printf("[d] volt:  %.2f\n", cs_state.batt_voltage);
      printf("[d] bl:    %i\n", cs_state.brightness);
      printf("[d] vol:   %i\n", cs_state.volume);
      printf("[d] mode:  %i\n", cs_state.mode_button_on);
      printf("[d] wifi:  %i\n", cs_state.wifi_state);
      printf("[d] mute:  %i\n", cs_state.mute_state);
      printf("[d] debug: %i\n", cs_state.debug_state);

      printf("-------------\n");
    }
  }

  return cs_state.power_switch_on;
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

void manager_init()
{
  printf("[*] manager_init..\n");

  state_init(); // Configure cs state
  socket_init();
}

//-----------------------------------------------------------------------------

void manager_unload()
{
  printf("[*] manager_unload..\n");

  state_unload();
  socket_unload();
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
