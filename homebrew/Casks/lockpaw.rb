cask "lockpaw" do
  version "1.6.3"
  sha256 "6f11ae97e33432e8c6ee48543f41f0d7eb358f60a123003edb6fa9a5fcff4653"

  url "https://github.com/sorkila/lockpaw/releases/download/v#{version}/Lockpaw.dmg"
  name "Lockpaw"
  desc "Cover your Mac screen while AI agents keep running"
  homepage "https://getlockpaw.com"

  depends_on macos: :sonoma

  app "Lockpaw.app"

  uninstall launchctl: "com.eriknielsen.lockpaw.helper"

  zap trash: [
    "~/Library/Preferences/com.eriknielsen.lockpaw.plist",
  ]
end
