class WaydroidCrew < Formula
  homepage "https://waydro.id"
  version "1.9"
  source_url "https://github.com/waydroid/waydroid.git"

  depends_on "git"
  depends_on "curl"
  depends_on "python3"
  depends_on "make"
  depends_on "gcc"

  def self.build
    # Clone the source repository
    system "git", "clone", "--depth", "1", source_url, "waydroid_src"
  end

  def self.install
    Dir.chdir("waydroid_src") do
      # Install using make install
      system "make", "install", "PREFIX=#{CREW_PREFIX}/opt/waydroid"

      # Symlink main executable into PATH
      system "ln -sf #{CREW_PREFIX}/opt/waydroid/waydroid #{CREW_PREFIX}/bin/waydroid"
    end

    # Clean up the source folder
    system "rm -rf waydroid_src"

    # Create a helper script to install & launch APKs
    script_dir = "#{ENV['HOME']}/.local/bin"
    system "mkdir -p #{script_dir}"
    File.open("#{script_dir}/waydroid-launch-apk.sh", "w") do |f|
      f.write <<~SCRIPT
        #!/bin/bash
        APK="$1"
        if [ -z "$APK" ]; then
          echo "No APK file specified."
          exit 1
        fi
        # Install APK in Waydroid
        waydroid install "$APK"
        # Extract package name
        PKG=$(aapt dump badging "$APK" | awk -F"'" '/package: name=/{print $2}')
        # Launch app
        waydroid app launch "$PKG"
      SCRIPT
    end
    system "chmod +x #{script_dir}/waydroid-launch-apk.sh"
    system "ln -sf #{script_dir}/waydroid-launch-apk.sh #{CREW_PREFIX}/bin/waydroid-launch-apk"

    # Create a .desktop file for APK association
    desktop_dir = "#{ENV['HOME']}/.local/share/applications"
    system "mkdir -p #{desktop_dir}"
    File.open("#{desktop_dir}/waydroid-apk.desktop", "w") do |f|
      f.write <<~DESKTOP
        [Desktop Entry]
        Name=Waydroid APK Launcher
        Exec=waydroid-launch-apk %f
        Icon=android
        Type=Application
        MimeType=application/vnd.android.package-archive
        NoDisplay=false
      DESKTOP
    end

    # Update MIME database
    system "update-desktop-database #{desktop_dir}"

    puts "Waydroid installed via Waydroid-crew!"
    puts "Double-click APKs to install and launch them in Waydroid."
  end
end
