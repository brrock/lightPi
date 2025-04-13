#!/bin/sh

CONFIG_FILE="/lightPi.txt"
MARKER_FILE="/etc/first-boot-done"

# --- Check if this is the first boot ---
if [ -f "$MARKER_FILE" ]; then
  echo "✅ First boot setup already completed. Skipping."
  exit 0
fi

# --- Check if config file exists ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file $CONFIG_FILE not found. Exiting."
  exit 1
fi

# --- Load config ---
echo "📄 Loading config from $CONFIG_FILE..."
source "$CONFIG_FILE"

# --- Set Locale ---
if [ -n "$LOCALE" ]; then
  echo "🌐 Configuring locale: $LOCALE"
  
  # Enable the locale in /etc/locale.gen if not already enabled
  if grep -q "^# *$LOCALE" /etc/locale.gen; then
    echo "🔧 Enabling $LOCALE in /etc/locale.gen"
    sed -i "s/^# *\($LOCALE\)/\1/" /etc/locale.gen
  elif ! grep -q "^$LOCALE" /etc/locale.gen; then
    echo "➕ Adding $LOCALE to /etc/locale.gen"
    echo "$LOCALE UTF-8" >> /etc/locale.gen
  fi

  echo "🛠️ Running locale-gen..."
  locale-gen

  echo "🌐 Setting system locale to $LOCALE"
  echo "LANG=$LOCALE" > /etc/locale.conf
else
  echo "⚠️ LOCALE not specified. Skipping locale setup."
fi

# --- Set Hostname (Arch-style) ---
if [ -n "$HOSTNAME" ]; then
  echo "🖥️ Setting hostname to $HOSTNAME"
  echo "$HOSTNAME" > /etc/hostname  # Simpler way for arch
  sed -i "s/127.0.0.1.*/127.0.0.1   $HOSTNAME localhost/" /etc/hosts
else
  echo "⚠️ HOSTNAME not specified. Skipping hostname setup."
fi

# --- Set Timezone ---
if [ -n "$TIMEZONE" ]; then
  echo "🕒 Setting timezone to $TIMEZONE"
  ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
else
  echo "⚠️ TIMEZONE not specified. Skipping timezone setup."
fi

# --- Network Setup (if nmcli is available) ---
if command -v nmcli >/dev/null 2>&1; then
  echo "📡 NetworkManager is available."

  case "$NETWORK_TYPE" in
    wifi)
      if [ -n "$WIFI_SSID" ] && [ -n "$WIFI_PASSWORD" ]; then
        echo "📶 Connecting to Wi-Fi: $WIFI_SSID"
        nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASSWORD" || {
          echo "❌ Failed to connect to Wi-Fi."
        }
      else
        echo "⚠️ WIFI_SSID or WIFI_PASSWORD missing. Skipping Wi-Fi setup."
      fi
      ;;
    ethernet)
      echo "🔌 Connecting via Ethernet (DHCP)"
      nmcli device connect eth0 || {
        echo "❌ Failed to bring up Ethernet."
      }
      ;;
    *)
      echo "⚠️ Unknown NETWORK_TYPE: $NETWORK_TYPE. Skipping network setup."
      ;;
  esac
else
  echo "⚠️ nmcli not found. Skipping network setup."
fi

# --- Finalize ---
touch "$MARKER_FILE"
echo "✅ First boot setup complete."

