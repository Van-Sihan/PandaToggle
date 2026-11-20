#!/bin/zsh
# ./build.sh          빌드만
# ./build.sh install  /Applications에 설치하고 로그인 시 자동 실행 등록
set -e
cd "$(dirname "$0")"
APP=build/PandaToggle.app
rm -rf build && mkdir -p $APP/Contents/MacOS
swiftc -O main.swift -o $APP/Contents/MacOS/PandaToggle
cat > $APP/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.jin.PandaToggle</string>
<key>CFBundleName</key><string>PandaToggle</string>
<key>CFBundleExecutable</key><string>PandaToggle</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>12.0</string>
</dict></plist>
PLIST
codesign --force -s - $APP
if [[ "$1" == "install" ]]; then
  pkill -x PandaToggle || true
  rm -rf /Applications/PandaToggle.app
  cp -R $APP /Applications/
  osascript -e 'tell application "System Events" to if not (exists login item "PandaToggle") then make login item at end with properties {path:"/Applications/PandaToggle.app", hidden:false}' || echo "로그인 항목 등록 실패: 시스템 설정 > 일반 > 로그인 항목에서 직접 추가하세요"
  open /Applications/PandaToggle.app
fi
