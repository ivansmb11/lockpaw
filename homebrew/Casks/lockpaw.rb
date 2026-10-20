cask "lockpaw" do
  version "1.6.4"
  sha256 "522a70d72a6575ff7132ae2e00a9fa20555ee0fcaa6dcc2fc59c8c6e70d8893e"

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
