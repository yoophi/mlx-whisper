APP_NAME = VoiceRecorder
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS

.PHONY: build bundle clean run install

build:
	swift build -c release

bundle: build
	@echo "Creating $(APP_BUNDLE)..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(MACOS_DIR)
	@cp $(BUILD_DIR)/$(APP_NAME) $(MACOS_DIR)/$(APP_NAME)
	@/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $(APP_NAME)" $(CONTENTS_DIR)/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.voicerecorder.app" $(CONTENTS_DIR)/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleName string $(APP_NAME)" $(CONTENTS_DIR)/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1.0" $(CONTENTS_DIR)/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" $(CONTENTS_DIR)/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" $(CONTENTS_DIR)/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" $(CONTENTS_DIR)/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :NSMicrophoneUsageDescription string '음성 인식을 위해 마이크 접근이 필요합니다.'" $(CONTENTS_DIR)/Info.plist
	@echo "$(APP_BUNDLE) created successfully."

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)

run: bundle
	$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)

install: bundle
	@echo "Installing to /Applications..."
	@cp -r $(APP_BUNDLE) /Applications/$(APP_BUNDLE)
	@echo "Installed to /Applications/$(APP_BUNDLE)"
