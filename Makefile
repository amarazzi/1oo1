APP_NAME    = 1001Daily
BUILD_DIR   = .build/release
APP_BUNDLE  = $(APP_NAME).app
APP_CONTENTS= $(APP_BUNDLE)/Contents
APP_MACOS   = $(APP_CONTENTS)/MacOS
APP_RES     = $(APP_CONTENTS)/Resources

.PHONY: all build bundle run clean kill

## Compile + bundle + launch in one step
all: bundle run

## Compile release binary
build:
	swift build -c release 2>&1

## Build the .app bundle
bundle: build
	@echo "📦  Assembling $(APP_BUNDLE)..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_MACOS) $(APP_RES)
	@cp $(BUILD_DIR)/$(APP_NAME) $(APP_MACOS)/$(APP_NAME)
	@cp 1001Daily/Resources/Info.plist $(APP_CONTENTS)/Info.plist
	@# Copy bundled JSON resources that SPM puts next to the binary
	@cp $(BUILD_DIR)/$(APP_NAME)_$(APP_NAME).bundle/movies_1001.json $(APP_RES)/movies_1001.json 2>/dev/null || \
	 cp $(BUILD_DIR)/movies_1001.json $(APP_RES)/movies_1001.json 2>/dev/null || \
	 find $(BUILD_DIR) -name "movies_1001.json" -exec cp {} $(APP_RES)/movies_1001.json \; 2>/dev/null || true
	@cp $(BUILD_DIR)/$(APP_NAME)_$(APP_NAME).bundle/albums_1001.json $(APP_RES)/albums_1001.json 2>/dev/null || \
	 cp $(BUILD_DIR)/albums_1001.json $(APP_RES)/albums_1001.json 2>/dev/null || \
	 find $(BUILD_DIR) -name "albums_1001.json" -exec cp {} $(APP_RES)/albums_1001.json \; 2>/dev/null || true
	@echo "✅  Bundle ready: $(APP_BUNDLE)"

## Launch the app
run:
	@echo "🚀  Launching $(APP_NAME)..."
	@open $(APP_BUNDLE)

## Kill running instance
kill:
	@pkill -x $(APP_NAME) 2>/dev/null || true
	@echo "🛑  Stopped $(APP_NAME)"

## Rebuild and relaunch (kill first)
restart: kill bundle run

## Clean everything
clean:
	@rm -rf $(APP_BUNDLE) .build
	@echo "🧹  Cleaned"
