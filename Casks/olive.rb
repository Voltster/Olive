cask "olive" do
  version "1.0.0"
  sha256 :no_check # Updated upon GitHub release tag

  url "https://github.com/Voltster/Olive/releases/download/v#{version}/Olive-#{version}.dmg"
  name "Olive"
  desc "Modern, privacy-first, open-source Mac optimizer and system monitor"
  homepage "https://github.com/Voltster/Olive"

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "Olive.app"

  zap trash: [
    "~/Library/Application Support/Olive",
    "~/Library/Caches/com.voltster.olive",
    "~/Library/Preferences/com.voltster.olive.plist",
    "~/Library/Logs/Olive",
  ]
end
