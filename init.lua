--- VPNProxy
--- Automatically sets and unsets the macOS system proxy and shell environment
--- variables (HTTP_PROXY / HTTPS_PROXY) when a corporate VPN connects or
--- disconnects. Useful for CLI tools that require the system proxy to reach
--- internal services.
---
--- Download: https://github.com/KimTholstorf/VPNProxy.spoon
--- License: MIT

local obj = {}
obj.__index = obj

--- Metadata
obj.name     = "VPNProxy"
obj.version  = "1.0"
obj.author   = "Kim Tholstorf"
obj.homepage = "https://github.com/KimTholstorf/VPNProxy.spoon"
obj.license  = "MIT - https://opensource.org/licenses/MIT"

--- Logger instance
obj.logger = hs.logger.new("VPNProxy")

--- VPNProxy.proxyHost
--- Variable
--- String containing the hostname of the corporate proxy server.
--- Must be set before calling start().
obj.proxyHost = nil

--- VPNProxy.proxyPort
--- Variable
--- String containing the port of the corporate proxy server.
--- Must be set before calling start().
obj.proxyPort = nil

--- VPNProxy.vpnCIDR
--- Variable
--- Lua pattern used to match the IPv4 address assigned to the VPN tunnel
--- interface (e.g. "^10%.154%."). Must be set before calling start().
--- To find the correct value: connect to VPN and run:
---   ifconfig | grep -A2 utun | grep "inet "
--- Take the first two octets of the IPv4 address and escape dots as %.:
---   10.154.85.241  ->  "^10%.154%."
obj.vpnCIDR = nil

--- VPNProxy.networkServices
--- Variable
--- Table of macOS network service names to apply proxy settings to.
--- Must be set before calling start().
--- To find valid names: run `networksetup -listallnetworkservices`
--- Exclude virtual interfaces such as Thunderbolt Bridge and Bluetooth.
obj.networkServices = {}

--- VPNProxy.proxyEnvFile
--- Variable
--- Path to the shell env file written on VPN connect/disconnect.
--- Defaults to ~/.config/proxy.env. Shell rc files should source this file.
obj.proxyEnvFile = os.getenv("HOME") .. "/.config/proxy.env"

-- Internal state
obj._watcher      = nil
obj._lastVPNState = nil

-- Private: apply or remove proxy settings
function obj:_setProxy(enable)
  for _, service in ipairs(self.networkServices) do
    if enable then
      hs.execute(string.format("networksetup -setwebproxy '%s' %s %s", service, self.proxyHost, self.proxyPort))
      hs.execute(string.format("networksetup -setsecurewebproxy '%s' %s %s", service, self.proxyHost, self.proxyPort))
    else
      hs.execute(string.format("networksetup -setwebproxystate '%s' off", service))
      hs.execute(string.format("networksetup -setsecurewebproxystate '%s' off", service))
    end
  end

  local f = io.open(self.proxyEnvFile, "w")
  if f then
    if enable then
      f:write(string.format("export HTTP_PROXY=http://%s:%s\n", self.proxyHost, self.proxyPort))
      f:write(string.format("export HTTPS_PROXY=http://%s:%s\n", self.proxyHost, self.proxyPort))
    else
      f:write("unset HTTP_PROXY\n")
      f:write("unset HTTPS_PROXY\n")
    end
    f:close()
  else
    self.logger.e("Could not write proxy env file: " .. self.proxyEnvFile)
  end
end

-- Private: check VPN state and act if changed
function obj:_onNetworkChange()
  local interfaces = hs.network.interfaces()
  local onVPN = false

  for _, iface in ipairs(interfaces) do
    if iface:match("^utun") then
      local details = hs.network.interfaceDetails(iface)
      if details and details["IPv4"] then
        local addr = details["IPv4"]["Addresses"] and details["IPv4"]["Addresses"][1] or ""
        if addr:match(self.vpnCIDR) then
          onVPN = true
          break
        end
      end
    end
  end

  if onVPN == self._lastVPNState then return end
  self._lastVPNState = onVPN

  if onVPN then
    self.logger.i("VPN connected — setting proxy")
    self:_setProxy(true)
    hs.notify.show("VPN", "", "Proxy set")
  else
    self.logger.i("VPN disconnected — clearing proxy")
    self:_setProxy(false)
    hs.notify.show("VPN", "", "Proxy cleared")
  end
end

--- VPNProxy:start()
--- Method
--- Starts VPNProxy. Validates configuration, registers the network watcher,
--- and immediately applies the correct proxy state.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The VPNProxy object
function obj:start()
  assert(self.proxyHost,            "VPNProxy: proxyHost is required")
  assert(self.proxyPort,            "VPNProxy: proxyPort is required")
  assert(self.vpnCIDR,              "VPNProxy: vpnCIDR is required")
  assert(#self.networkServices > 0, "VPNProxy: networkServices is required")

  self._watcher = hs.network.configuration.open()
  self._watcher:setCallback(function() self:_onNetworkChange() end)
  self._watcher:monitorKeys({
    "State:/Network/Interface",
    "State:/Network/Global/IPv4"
  })
  self._watcher:start()

  self:_onNetworkChange()

  return self
end

--- VPNProxy:stop()
--- Method
--- Stops VPNProxy and unregisters the network watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The VPNProxy object
function obj:stop()
  if self._watcher then
    self._watcher:stop()
    self._watcher = nil
    self.logger.i("VPNProxy stopped")
  end
  return self
end

return obj
