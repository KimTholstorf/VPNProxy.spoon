#!/usr/bin/env bash
# bin/install.sh
#
# Installs and configures VPNProxy.spoon for Hammerspoon.
# Can be run directly from GitHub without cloning first:
#
#   bash <(curl -s https://raw.githubusercontent.com/KimTholstorf/VPNProxy.spoon/main/bin/install.sh)
#
# Prerequisites:
#   - Homebrew (https://brew.sh)
#   - Git
#   - Corporate VPN credentials (needed during configure step)

set -e

REPO_URL="https://github.com/KimTholstorf/VPNProxy.spoon.git"
SPOON_DST="$HOME/.hammerspoon/Spoons/VPNProxy.spoon"
CONFIGURE_SCRIPT="$SPOON_DST/bin/configure-VPNProxy.sh"

# ── Output helpers ─────────────────────────────────────────────────────────────

BOLD=$(tput bold 2>/dev/null || true)
RED=$(tput setaf 1 2>/dev/null || true)
GREEN=$(tput setaf 2 2>/dev/null || true)
YELLOW=$(tput setaf 3 2>/dev/null || true)
CYAN=$(tput setaf 6 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)

header()  { echo; echo "${BOLD}${CYAN}══ $1 ══${RESET}"; echo; }
success() { echo "  ${GREEN}✅ $1${RESET}"; }
info()    { echo "  ${CYAN}→  $1${RESET}"; }
warn()    { echo "  ${YELLOW}⚠️  $1${RESET}"; }
error()   { echo; echo "  ${RED}${BOLD}ERROR: $1${RESET}"; echo; }
ask()     { printf "  ${BOLD}$1${RESET} "; }

# ── Header ─────────────────────────────────────────────────────────────────────

clear
echo
echo "${BOLD}${CYAN}╔══════════════════════════════════════════╗${RESET}"
echo "${BOLD}${CYAN}║        VPNProxy.spoon  Installer         ║${RESET}"
echo "${BOLD}${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo
echo "  Automatically sets and unsets the macOS system proxy"
echo "  and shell environment variables when your VPN connects"
echo "  or disconnects."
echo
echo "  ${CYAN}https://github.com/KimTholstorf/VPNProxy.spoon${RESET}"
echo

# ── Step 1 — Preflight ─────────────────────────────────────────────────────────

header "Step 1 — Preflight checks"

if ! command -v git >/dev/null 2>&1; then
  error "Git is not installed."
  echo "  Install Xcode Command Line Tools by running:"
  echo "    ${BOLD}xcode-select --install${RESET}"
  exit 1
fi
success "Git found"

if ! command -v brew >/dev/null 2>&1; then
  if [ ! -d "/Applications/Hammerspoon.app" ]; then
    error "Homebrew is not installed and Hammerspoon was not found."
    echo "  Either install Homebrew from ${BOLD}https://brew.sh${RESET}"
    echo "  or download Hammerspoon manually from ${BOLD}https://hammerspoon.org${RESET}"
    echo "  then re-run this installer."
    exit 1
  fi
  warn "Homebrew not found but Hammerspoon is already installed"
else
  success "Homebrew found"
fi

# ── Step 2 — Hammerspoon ───────────────────────────────────────────────────────

header "Step 2 — Install Hammerspoon"

if [ -d "/Applications/Hammerspoon.app" ]; then
  success "Hammerspoon is already installed"
else
  info "Hammerspoon not found — installing via Homebrew..."
  echo
  brew install --cask hammerspoon
  echo
  success "Hammerspoon installed"
fi

# ── Step 3 — Spoons directory ──────────────────────────────────────────────────

header "Step 3 — Hammerspoon directories"

mkdir -p "$HOME/.hammerspoon/Spoons"
success "~/.hammerspoon/Spoons is ready"

# ── Step 4 — Clone or update VPNProxy.spoon ───────────────────────────────────

header "Step 4 — VPNProxy.spoon"

if [ -d "$SPOON_DST/.git" ]; then
  info "VPNProxy.spoon already installed — pulling latest changes..."
  echo
  git -C "$SPOON_DST" checkout main 2>/dev/null
  git -C "$SPOON_DST" pull origin main
  echo
  success "VPNProxy.spoon updated"
else
  info "Cloning VPNProxy.spoon into $SPOON_DST..."
  echo
  git clone "$REPO_URL" "$SPOON_DST"
  echo
  success "VPNProxy.spoon installed"
fi

# ── Step 5 — Shell rc files ───────────────────────────────────────────────────

header "Step 5 — Shell configuration"

add_to_rc() {
  RC_FILE="$1"
  if [ -f "$RC_FILE" ]; then
    if ! grep -q "proxy.env" "$RC_FILE"; then
      echo '[ -f ~/.config/proxy.env ] && . ~/.config/proxy.env' >> "$RC_FILE"
      success "Added proxy.env sourcing to $RC_FILE"
    else
      success "$RC_FILE already configured"
    fi
  fi
}

add_to_rc "$HOME/.zshrc"
add_to_rc "$HOME/.bashrc"
add_to_rc "$HOME/.bash_profile"

# ── Step 6 — Configure ────────────────────────────────────────────────────────

header "Step 6 — Configure VPNProxy"

echo "  The configuration step detects your proxy settings and VPN CIDR"
echo "  automatically — but it ${BOLD}requires an active VPN connection${RESET} to do so."
echo
ask "Do you want to run configuration now? [y/N]"
read -r RUN_CONFIG

case "$RUN_CONFIG" in
  y|Y)

    # ── VPN pause screen ──────────────────────────────────────────────────────

    clear
    echo
    echo "${BOLD}${YELLOW}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo "${BOLD}${YELLOW}║                                                              ║${RESET}"
    echo "${BOLD}${YELLOW}║   ⚠️   BEFORE YOU CONTINUE — CONNECT TO YOUR CORPORATE VPN   ║${RESET}"
    echo "${BOLD}${YELLOW}║                                                              ║${RESET}"
    echo "${BOLD}${YELLOW}╠══════════════════════════════════════════════════════════════╣${RESET}"
    echo "${BOLD}${YELLOW}║                                                              ║${RESET}"
    echo "${BOLD}${YELLOW}║  The next step will auto-detect:                             ║${RESET}"
    echo "${BOLD}${YELLOW}║    • Your VPN tunnel IP and CIDR pattern                     ║${RESET}"
    echo "${BOLD}${YELLOW}║    • Your corporate proxy host and port                      ║${RESET}"
    echo "${BOLD}${YELLOW}║    • Your active network services                            ║${RESET}"
    echo "${BOLD}${YELLOW}║                                                              ║${RESET}"
    echo "${BOLD}${YELLOW}║  None of this can be detected without an active VPN.         ║${RESET}"
    echo "${BOLD}${YELLOW}║                                                              ║${RESET}"
    echo "${BOLD}${YELLOW}╠══════════════════════════════════════════════════════════════╣${RESET}"
    echo "${BOLD}${YELLOW}║                                                              ║${RESET}"
    echo "${BOLD}${YELLOW}║   Connect to VPN now, then press any key to continue...      ║${RESET}"
    echo "${BOLD}${YELLOW}║                                                              ║${RESET}"
    echo "${BOLD}${YELLOW}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    read -r -s -n1

    # ── Run configure-VPNProxy.sh ─────────────────────────────────────────────

    echo
    header "Configuring VPNProxy.spoon"

    if [ ! -f "$CONFIGURE_SCRIPT" ]; then
      error "configure-VPNProxy.sh not found at $CONFIGURE_SCRIPT"
      exit 1
    fi

    chmod +x "$CONFIGURE_SCRIPT"
    "$CONFIGURE_SCRIPT"
    ;;

  *)
    echo
    warn "Skipping configuration — no changes made to init.lua."
    echo
    echo "  When you are ready to configure (you'll need to be on VPN), run:"
    echo
    echo "    ${BOLD}$CONFIGURE_SCRIPT${RESET}"
    echo
    echo "  Or re-run this installer:"
    echo
    echo "    ${BOLD}bash <(curl -s https://raw.githubusercontent.com/KimTholstorf/VPNProxy.spoon/main/bin/install.sh)${RESET}"
    echo
    echo "  ${CYAN}Note:${RESET} The spoon has been installed to:"
    echo "    ${BOLD}$SPOON_DST${RESET}"
    echo "  It will not activate until configure-VPNProxy.sh has been run and"
    echo "  Hammerspoon has been reloaded."
    echo
    exit 0
    ;;
esac

# ── Step 7 — Restart Hammerspoon ──────────────────────────────────────────────

header "Step 7 — Restart Hammerspoon"

ask "Restart Hammerspoon now to apply the new configuration? [Y/n]"
read -r RESTART_HS

case "$RESTART_HS" in
  n|N)
    warn "Skipping restart — remember to reload Hammerspoon manually."
    ;;
  *)
    info "Restarting Hammerspoon..."
    killall Hammerspoon 2>/dev/null || true
    sleep 1
    open -a Hammerspoon
    success "Hammerspoon restarted"
    ;;
esac

# ── Done ──────────────────────────────────────────────────────────────────────

echo
echo "${BOLD}${GREEN}╔══════════════════════════════════════════╗${RESET}"
echo "${BOLD}${GREEN}║         Installation complete! 🎉        ║${RESET}"
echo "${BOLD}${GREEN}╚══════════════════════════════════════════╝${RESET}"
echo
echo "  ${BOLD}Post-install checklist:${RESET}"
echo
echo "  ${YELLOW}1.${RESET} Open Hammerspoon preferences (menubar icon → Preferences)"
echo "     and enable ${BOLD}Accessibility${RESET}"
echo
echo "  ${YELLOW}2.${RESET} Enable ${BOLD}Launch Hammerspoon at Login${RESET} in preferences"
echo
echo "  ${YELLOW}3.${RESET} Open a new terminal and verify the proxy is active:"
echo "     ${BOLD}echo \$HTTPS_PROXY${RESET}"
echo
echo "  ${YELLOW}4.${RESET} Test that CLI tools can reach internal services:"
echo "     ${BOLD}curl -sv https://internal.example.com${RESET}"
echo
echo "  ${CYAN}Spoon location:${RESET}  $SPOON_DST"
echo "  ${CYAN}Hammerspoon config:${RESET}  ~/.hammerspoon/init.lua"
echo "  ${CYAN}Proxy env file:${RESET}  ~/.config/proxy.env"
echo
