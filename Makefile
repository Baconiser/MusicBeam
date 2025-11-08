BASE_DIR := $(shell pwd)
BUILD_DIR := $(BASE_DIR)/MusicBeam
SOURCE_DIR := $(BASE_DIR)/MusicBeam
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

PROCESSING_VERSION := 4.4.10
PROCESSING_RELEASE_TAG := processing-1310-$(PROCESSING_VERSION)
PROCESSING_ROOT := $(BASE_DIR)/.processing
PROCESSING_DIR := $(PROCESSING_ROOT)/processing-$(PROCESSING_VERSION)
PROCESSING_DOWNLOAD_BASE := https://github.com/processing/processing4/releases/download/$(PROCESSING_RELEASE_TAG)

ifeq ($(UNAME_S),Linux)
  ifeq ($(UNAME_M),x86_64)
    PROCESSING_ARCHIVE := processing-$(PROCESSING_VERSION)-linux-x64.tgz
  else ifeq ($(UNAME_M),aarch64)
    PROCESSING_ARCHIVE := processing-$(PROCESSING_VERSION)-linux-aarch64.tgz
  else ifeq ($(UNAME_M),armv7l)
    PROCESSING_ARCHIVE := processing-$(PROCESSING_VERSION)-linux-armv6hf.tgz
  else
    $(error Unsupported Linux architecture $(UNAME_M))
  endif
  PROCESSING_JAVA := $(PROCESSING_DIR)/processing-java
  PROCESSING_EXTRACT_CMD = tar -xzf "$(PROCESSING_ARCHIVE_PATH)" -C "$(PROCESSING_ROOT)"
else ifeq ($(UNAME_S),Darwin)
  ifeq ($(UNAME_M),x86_64)
    PROCESSING_ARCHIVE := processing-$(PROCESSING_VERSION)-macos-x64.zip
  else ifeq ($(UNAME_M),arm64)
    PROCESSING_ARCHIVE := processing-$(PROCESSING_VERSION)-macos-arm64.zip
  else
    $(error Unsupported macOS architecture $(UNAME_M))
  endif
  PROCESSING_JAVA := $(PROCESSING_DIR)/Processing.app/Contents/MacOS/processing-java
  PROCESSING_EXTRACT_CMD = unzip -q "$(PROCESSING_ARCHIVE_PATH)" -d "$(PROCESSING_DIR)"
else
  $(error Unsupported host OS $(UNAME_S))
endif

PROCESSING_ARCHIVE_PATH := $(PROCESSING_ROOT)/$(PROCESSING_ARCHIVE)
PROCESSING_URL := $(PROCESSING_DOWNLOAD_BASE)/$(PROCESSING_ARCHIVE)

ARCHS = linux-aarch64 linux-amd64 linux-arm macos-aarch64 macos-x86_64 windows-amd64
ZIPS = $(ARCHS:%=$(BUILD_DIR)/MusicBeam-%.zip)

.PHONY: all clean processing download

all: $(BUILD_DIR) $(ZIPS)

processing: $(PROCESSING_JAVA)

download: $(PROCESSING_ARCHIVE_PATH)

$(PROCESSING_ARCHIVE_PATH):
	mkdir -p "$(PROCESSING_ROOT)"
	curl -L "$(PROCESSING_URL)" -o "$@"

$(PROCESSING_JAVA): $(PROCESSING_ARCHIVE_PATH)
	rm -rf "$(PROCESSING_DIR)"
	mkdir -p "$(PROCESSING_DIR)"
	$(PROCESSING_EXTRACT_CMD)
	rm -f "$(PROCESSING_ARCHIVE_PATH)"
	chmod +x "$(PROCESSING_JAVA)"

$(SOURCE_DIR)/%: $(PROCESSING_JAVA)
	rm -rf "$@"
	"$(PROCESSING_JAVA)" --sketch="$(SOURCE_DIR)" --output="$@" --force --export --variant=$*

$(BUILD_DIR):
	mkdir -p "$(BUILD_DIR)"

$(BUILD_DIR)/MusicBeam-%.zip: $(SOURCE_DIR)/% | $(BUILD_DIR)
	(cd "$(SOURCE_DIR)/$*" && zip -r "$(BUILD_DIR)/MusicBeam-$*.zip" ./*)
	zip "$(BUILD_DIR)/MusicBeam-$*.zip" LICENSE README.md

$(BUILD_DIR)/MusicBeam-macos-aarch64.zip: $(SOURCE_DIR)/macos-aarch64 | $(BUILD_DIR)
	cp "$(SOURCE_DIR)/sketch.icns" "$(SOURCE_DIR)/macos-aarch64/MusicBeam.app/Contents/Resources/sketch.icns"
	codesign --force --sign - "$(SOURCE_DIR)/macos-aarch64/MusicBeam.app"
	(cd "$(SOURCE_DIR)/macos-aarch64" && zip -r "$(BUILD_DIR)/MusicBeam-macos-aarch64.zip" ./*)
	zip "$(BUILD_DIR)/MusicBeam-macos-aarch64.zip" LICENSE README.md

$(BUILD_DIR)/MusicBeam-macos-x86_64.zip: $(SOURCE_DIR)/macos-x86_64 | $(BUILD_DIR)
	cp "$(SOURCE_DIR)/sketch.icns" "$(SOURCE_DIR)/macos-x86_64/MusicBeam.app/Contents/Resources/sketch.icns"
	codesign --force --sign - "$(SOURCE_DIR)/macos-x86_64/MusicBeam.app"
	(cd "$(SOURCE_DIR)/macos-x86_64" && zip -r "$(BUILD_DIR)/MusicBeam-macos-x86_64.zip" ./*)
	zip "$(BUILD_DIR)/MusicBeam-macos-x86_64.zip" LICENSE README.md

clean:
	-for dir in $(ARCHS); do \
		rm -rf "$(SOURCE_DIR)/$${dir}"; \
	done
	-rm $(ZIPS)
