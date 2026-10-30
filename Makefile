UPGRADE_EDITOR_DIR := tools/upgrade_editor

.PHONY: upgrades upgrades-export upgrades-apply upgrades-test upgrades-game-to-app upgrades-app-to-game

upgrades:
	cd $(UPGRADE_EDITOR_DIR) && exec python3 -m upgrade_editor serve

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
