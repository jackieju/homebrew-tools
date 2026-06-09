class AiAgentSmartVoiceInput < Formula
  desc "macOS voice input tool for AI agent terminals (opencode)"
  homepage "https://github.com/jackieju/AIAgentSmartVoiceInput"
  url "https://github.com/jackieju/AIAgentSmartVoiceInput/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "4ff1916610d9d42d18ec1c5e83661be7bbd7ab2503995bade1540fd743c0198f"
  license "MIT"

  depends_on :macos
  depends_on "whisper-cpp"

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/VoiceInput" => "voiceinput"

    system "swiftc", "-O", "-o", "inject-helper",
           "inject-helper.swift",
           "-framework", "AppKit",
           "-framework", "CoreGraphics",
           "-framework", "Carbon"
    bin.install "inject-helper"

    bin.install "start-daemon.command"

    (prefix/"VoiceInput.app/Contents/MacOS").mkpath
    cp bin/"voiceinput", prefix/"VoiceInput.app/Contents/MacOS/VoiceInput"
    cp "VoiceInput.app/Contents/Info.plist", prefix/"VoiceInput.app/Contents/Info.plist"
    system "codesign", "-s", "-", "--force", "--deep",
           "--entitlements", "VoiceInput.entitlements",
           prefix/"VoiceInput.app"
  end

  def post_install
    mkdir_p "#{Dir.home}/.local/share/whisper-cpp/models"
  end

  def caveats
    <<~EOS
      To start VoiceInput:
        open #{prefix}/VoiceInput.app

      To enable auto-start and auto-restart:
        cp #{prefix}/com.voiceinput.app.plist ~/Library/LaunchAgents/
        launchctl load ~/Library/LaunchAgents/com.voiceinput.app.plist

      You must grant permissions in System Settings → Privacy & Security:
        - Microphone: VoiceInput.app
        - Accessibility: inject-helper

      Download a whisper model (if not already installed):
        curl -L -o ~/.local/share/whisper-cpp/models/ggml-large-v3-turbo.bin \\
          "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"

      Hotkeys:
        Option+Shift+V  - Start/stop recording
        Escape          - Cancel recording
    EOS
  end

  test do
    assert_predicate bin/"voiceinput", :exist?
    assert_predicate bin/"inject-helper", :exist?
  end
end
