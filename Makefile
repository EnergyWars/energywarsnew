UPGRADE_EDITOR_DIR := tools/upgrade_editor

.PHONY: upgrades upgrades-lan upgrades-export upgrades-apply upgrades-test upgrades-game-to-app upgrades-app-to-game

upgrades:
	cd $(UPGRADE_EDITOR_DIR) && exec python3 -m upgrade_editor serve

upgrades-lan:
	cd $(UPGRADE_EDITOR_DIR) && exec python3 -m upgrade_editor serve --host 0.0.0.0

upgrades-export:
	$(UPGRADE_EDITOR_DIR)/export.sh

upgrades-apply:
	cd $(UPGRADE_EDITOR_DIR) && python3 -m upgrade_editor apply

upgrades-test:
	cd $(UPGRADE_EDITOR_DIR) && python3 -m unittest discover -s tests/py -t . && node --test tests/js

upgrades-game-to-app:
	$(UPGRADE_EDITOR_DIR)/game-to-app.sh

upgrades-app-to-game:
	$(UPGRADE_EDITOR_DIR)/app-to-game.sh

GODOT ?= $(HOME)/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
BUILD_DIR := build
RELEASE_KEYSTORE_VARS := GODOT_ANDROID_KEYSTORE_RELEASE_PATH GODOT_ANDROID_KEYSTORE_RELEASE_USER GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD

.PHONY: test import store-assets android-debug android-aab android-release-check

import:
	$(GODOT) --headless --import

test: import
	$(GODOT) --headless -s addons/gut/gut_cmdln.gd

store-assets:
	$(GODOT) --headless -s tools/store_assets/render_icons.gd
	python3 -I tools/store_assets/feature_graphic.py

android-debug:
	mkdir -p $(BUILD_DIR)
	$(GODOT) --headless --export-debug "Android" $(BUILD_DIR)/energy-wars.apk

android-release-check:
	@for name in $(RELEASE_KEYSTORE_VARS); do \
		if [ -z "$$(printenv $$name)" ]; then echo "missing environment variable $$name"; exit 1; fi; \
	done
	@test -d android/build || (echo "missing android/build: install the Android build template in the editor" && exit 1)

android-aab: android-release-check test
	mkdir -p $(BUILD_DIR)
	$(GODOT) --headless --export-release "Android Play" $(BUILD_DIR)/energy-wars.aab
