<div align="center">
  <img src="logo_gh.png" width="256" height="256" alt="csvTrim Logo"/>
  <h1 align="center">VPNProxy.spoon</h1>
  <h4 align="center">Automatic proxy switching for macOS when your corporate VPN connects or disconnects</h4>
</div>

<br>

VPNProxy.spoon is a [Hammerspoon](https://hammerspoon.org) spoon that watches your network interfaces and automatically sets or clears the macOS system proxy and shell environment variables (`HTTP_PROXY` / `HTTPS_PROXY`) the moment your corporate VPN connects or disconnects. No menu bar clicks, no manual proxy toggling — it just works.

## 🪚 Features

- **Automatic detection** — monitors network state changes in real time via Hammerspoon's network watcher
- **System proxy** — sets and clears macOS proxy settings via `networksetup` for all configured network services
- **Shell environment** — updates `~/.config/proxy.env` on every VPN state change; shell rc files source this file so all new terminal sessions automatically inherit the correct proxy state
- **VPN CIDR matching** — identifies the VPN tunnel by matching the assigned IP against a configurable Lua pattern
- **Multi-service support** — applies proxy settings to multiple network services simultaneously (Wi-Fi, Ethernet, USB adapters)
- **Desktop notifications** — shows a macOS notification when proxy is set or cleared
- **Auto-configuration** — installer detects VPN CIDR, proxy host/port, and network services automatically from your live VPN connection

---

## 👷 Quick start

Connect to your corporate VPN, then run:

```bash
bash <(curl -s https://raw.githubusercontent.com/KimTholstorf/VPNProxy.spoon/main/bin/install.sh)
```

The installer will:
1. Install Hammerspoon if needed (via Homebrew)
2. Clone VPNProxy.spoon into `~/.hammerspoon/Spoons/`
3. Patch your shell rc files to source `~/.config/proxy.env`
4. Auto-detect your VPN and proxy settings and write `~/.hammerspoon/init.lua`
5. Offer to restart Hammerspoon

---

## 🏗️ Requirements

- macOS 13 or later
- [Hammerspoon](https://hammerspoon.org) (installed automatically if missing)
- [Homebrew](https://brew.sh) — only required if Hammerspoon is not already installed
- Git
- Corporate VPN connection — required during the configure step for auto-detection

---

## 📦 Installation

### One-liner (recommended)

```bash
bash <(curl -s https://raw.githubusercontent.com/KimTholstorf/VPNProxy.spoon/main/bin/install.sh)
```

### Manual

```bash
# Clone into your Hammerspoon Spoons directory
git clone https://github.com/KimTholstorf/VPNProxy.spoon.git \
  ~/.hammerspoon/Spoons/VPNProxy.spoon
```

**Shell rc files** — add the following line to `~/.zshrc`, `~/.bashrc`, and/or `~/.bash_profile` so new terminal sessions pick up the proxy state:

```bash
[ -f ~/.config/proxy.env ] && . ~/.config/proxy.env
```

**Hammerspoon init.lua** — either run the auto-detect script (requires VPN connection):

```bash
~/.hammerspoon/Spoons/VPNProxy.spoon/bin/configure-VPNProxy.sh
```

Or configure manually by editing `~/.hammerspoon/init.lua` using [`init.lua.template`](init.lua.template) as a reference — fill in your `proxyHost`, `proxyPort`, `vpnCIDR`, and `networkServices` values.

---

## ⚙️ Configuration

Configuration is handled by `bin/configure-VPNProxy.sh` — the installer will offer to run this automatically as part of the install flow. To run it standalone, connect to your corporate VPN and run:

```bash
~/.hammerspoon/Spoons/VPNProxy.spoon/bin/configure-VPNProxy.sh
```

The script auto-detects and writes the following values into `~/.hammerspoon/init.lua`:

| Value | How it's detected |
|---|---|
| `proxyHost` / `proxyPort` | PAC file (via `scutil --proxy`) or `$http_proxy` env var |
| `vpnCIDR` | First two octets of the VPN tunnel IP from `ifconfig` |
| `networkServices` | `networksetup -listallnetworkservices` (excluding virtual interfaces) |

If `init.lua` already contains a VPNProxy config block, the script will show the detected values and ask before overwriting.

To configure manually, edit `~/.hammerspoon/init.lua` directly — see [`init.lua.template`](init.lua.template) for the expected format.

---

## 🔍 How it works

```
VPN connects
    └── Hammerspoon detects network change
            └── VPNProxy checks utun interfaces for matching CIDR
                    ├── Match found
                    │     ├── networksetup sets proxy for all configured services
                    │     ├── writes export HTTP_PROXY / HTTPS_PROXY to ~/.config/proxy.env
                    │     └── shows "Proxy set" notification
                    └── No match (VPN disconnected)
                          ├── networksetup clears proxy for all configured services
                          ├── writes unset HTTP_PROXY / HTTPS_PROXY to ~/.config/proxy.env
                          └── shows "Proxy cleared" notification

New terminal session
    └── shell rc sources ~/.config/proxy.env
            └── HTTP_PROXY / HTTPS_PROXY reflect current VPN state
```

---

## 📁 Repository layout

```
VPNProxy.spoon/
├── init.lua                  # The Hammerspoon spoon
├── init.lua.template         # Documents the expected init.lua format
├── bin/
│   ├── install.sh            # Full installer — installs and configures in one flow
│   └── configure-VPNProxy.sh # Auto-detects VPN values and writes init.lua
└── README.md
```

---

## 🔧 Re-running after network changes

If your corporate VPN changes proxy, CIDR, or you add a new network adapter, re-run the configuration script while connected to VPN:

```bash
~/.hammerspoon/Spoons/VPNProxy.spoon/bin/configure-VPNProxy.sh
```

Then reload Hammerspoon: menubar icon → **Reload Config**.

---

## 🔒 Permissions

Hammerspoon requires **Accessibility** access to function. On first launch, open Hammerspoon preferences from the menubar icon and enable:

- ✅ Enable Accessibility
- ✅ Launch Hammerspoon at Login

---

## 📄 License

MIT — see [LICENSE](LICENSE) for details.
