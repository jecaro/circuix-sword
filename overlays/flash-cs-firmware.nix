final: prev:
{
  flash-cs-firmware = final.writeShellApplication
    {
      name = "flash-cs-firmware";

      runtimeInputs = [ final.arduino-cli-with-hid ];

      text = ''
        if [[ $EUID -ne 0 ]]; then
          echo "This script must be run as root." >&2
          exit 1
        fi

        echo "Stopping cs-hud service"
        systemctl stop cs-hud

        echo "Flashing firmware"
        arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:avr:leonardo --input-dir ${final.cs-firmware}
        echo "Starting cs-hud service"
        systemctl start cs-hud

        echo "Done"
      '';
    };
}

