BASE_DIR := $(shell pwd)
BUILD_DIR := $(BASE_DIR)/build
SOURCE_DIR := $(BASE_DIR)/MusicBeam
TOOLS_DIR := $(BASE_DIR)/tools

# Processing version
PROCESSING_VERSION := 4.4.10
PROCESSING_TAG := processing-1310-4.4.10
PROCESSING_BASE_URL := https://github.com/processing/processing4/releases/download/$(PROCESSING_TAG)

# Platform-specific Processing downloads
PROCESSING_LINUX_URL := $(PROCESSING_BASE_URL)/processing-$(PROCESSING_VERSION)-linux-x64.tgz
PROCESSING_LINUX_ARM64_URL := $(PROCESSING_BASE_URL)/processing-$(PROCESSING_VERSION)-linux-aarch64.tgz
PROCESSING_MACOS_X64_URL := $(PROCESSING_BASE_URL)/processing-$(PROCESSING_VERSION)-macos-x64.zip
PROCESSING_MACOS_ARM64_URL := $(PROCESSING_BASE_URL)/processing-$(PROCESSING_VERSION)-macos-aarch64.zip
PROCESSING_WINDOWS_URL := $(PROCESSING_BASE_URL)/processing-$(PROCESSING_VERSION)-windows-x64.zip

# Processing-java executable
PROCESSING_JAVA := $(TOOLS_DIR)/processing-$(PROCESSING_VERSION)/processing-java

ARCHS = linux-aarch64 linux-amd64 linux-arm macos-aarch64 macos-x86_64 windows-amd64
ZIPS = $(ARCHS:%=$(BUILD_DIR)/MusicBeam-%.zip)

.PHONY: all clean clean-tools build-all download-processing build-linux-amd64 build-linux-aarch64 build-linux-arm build-macos-x86_64 build-macos-aarch64 build-windows-amd64

$(BUILD_DIR):
	mkdir -p "$(BUILD_DIR)"

$(TOOLS_DIR):
	mkdir -p "$(TOOLS_DIR)"

# Download Processing for Linux x64 (used for building)
download-processing: $(TOOLS_DIR)
	@if [ ! -f "$(PROCESSING_JAVA)" ]; then \
		echo "Downloading Processing $(PROCESSING_VERSION) for Linux x64..."; \
		wget -q -O "$(TOOLS_DIR)/processing.tgz" "$(PROCESSING_LINUX_URL)"; \
		echo "Extracting Processing..."; \
		tar -xzf "$(TOOLS_DIR)/processing.tgz" -C "$(TOOLS_DIR)"; \
		rm "$(TOOLS_DIR)/processing.tgz"; \
		echo "Processing $(PROCESSING_VERSION) installed."; \
	else \
		echo "Processing $(PROCESSING_VERSION) already installed."; \
	fi

# Build for specific platforms
build-linux-amd64: download-processing $(BUILD_DIR)
	$(PROCESSING_JAVA) --sketch="$(SOURCE_DIR)" --output="$(BUILD_DIR)/linux-amd64" --platform=linux --variant=linux-amd64 --export

build-linux-aarch64: download-processing $(BUILD_DIR)
	$(PROCESSING_JAVA) --sketch="$(SOURCE_DIR)" --output="$(BUILD_DIR)/linux-aarch64" --platform=linux --variant=linux-aarch64 --export

build-linux-arm: download-processing $(BUILD_DIR)
	$(PROCESSING_JAVA) --sketch="$(SOURCE_DIR)" --output="$(BUILD_DIR)/linux-arm" --platform=linux --variant=linux-arm --export

build-macos-x86_64: download-processing $(BUILD_DIR)
	$(PROCESSING_JAVA) --sketch="$(SOURCE_DIR)" --output="$(BUILD_DIR)/macos-x86_64" --platform=macosx --variant=macosx-x86_64 --export

build-macos-aarch64: download-processing $(BUILD_DIR)
	$(PROCESSING_JAVA) --sketch="$(SOURCE_DIR)" --output="$(BUILD_DIR)/macos-aarch64" --platform=macosx --variant=macosx-aarch64 --export

build-windows-amd64: download-processing $(BUILD_DIR)
	$(PROCESSING_JAVA) --sketch="$(SOURCE_DIR)" --output="$(BUILD_DIR)/windows-amd64" --platform=windows --variant=windows-amd64 --export

# Build all platforms
build-all: build-linux-amd64 build-linux-aarch64 build-linux-arm build-macos-x86_64 build-macos-aarch64 build-windows-amd64

$(BUILD_DIR)/MusicBeam-%.zip: build-%
	(cd "$(BUILD_DIR)/$(*)" && zip -r "$(BUILD_DIR)/MusicBeam-$(*).zip" ./*)
	zip "$(BUILD_DIR)/MusicBeam-$(*).zip" LICENSE README.md

$(BUILD_DIR)/MusicBeam-macos-aarch64.zip: build-macos-aarch64
	cp "$(SOURCE_DIR)/sketch.icns" "$(BUILD_DIR)/macos-aarch64/MusicBeam.app/Contents/Resources/sketch.icns"
	codesign --force --sign - "$(BUILD_DIR)/macos-aarch64/MusicBeam.app"
	(cd "$(BUILD_DIR)/macos-aarch64" && zip -r "$(BUILD_DIR)/MusicBeam-macos-aarch64.zip" ./*)
	zip "$(BUILD_DIR)/MusicBeam-macos-aarch64.zip" LICENSE README.md

$(BUILD_DIR)/MusicBeam-macos-x86_64.zip: build-macos-x86_64
	cp "$(SOURCE_DIR)/sketch.icns" "$(BUILD_DIR)/macos-x86_64/MusicBeam.app/Contents/Resources/sketch.icns"
	codesign --force --sign - "$(BUILD_DIR)/macos-x86_64/MusicBeam.app"
	(cd "$(BUILD_DIR)/macos-x86_64" && zip -r "$(BUILD_DIR)/MusicBeam-macos-x86_64.zip" ./*)
	zip "$(BUILD_DIR)/MusicBeam-macos-x86_64.zip" LICENSE README.md

all: build-all $(ZIPS)

clean:
	-rm -rf "$(BUILD_DIR)"

clean-tools:
	-rm -rf "$(TOOLS_DIR)"
