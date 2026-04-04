FASTLANE ?= fastlane
PLATFORM ?= ios

.PHONY: help lanes validate local-build release-existing release-new metadata-only install-template

help:
	@echo "Targets:"
	@echo "  make lanes"
	@echo "  make validate"
	@echo "  make local-build SCHEME=MyApp EXPORT_METHOD=development"
	@echo "  make release-existing SCHEME=MyApp APP_IDENTIFIER=com.example.app"
	@echo "  make release-new SCHEME=MyApp APP_IDENTIFIER=com.example.app APP_NAME=MyApp SKU=myapp001"
	@echo "  make metadata-only APP_IDENTIFIER=com.example.app"
	@echo "  make install-template TARGET_DIR=/path/to/project"

lanes:
	$(FASTLANE) lanes

validate:
	$(FASTLANE) $(PLATFORM) validate_setup

local-build:
	$(FASTLANE) $(PLATFORM) local_build \
		scheme:"$(SCHEME)" \
		export_method:"$(or $(EXPORT_METHOD),development)"

release-existing:
	$(FASTLANE) $(PLATFORM) release_existing \
		scheme:"$(SCHEME)" \
		app_identifier:"$(APP_IDENTIFIER)" \
		version:"$(VERSION)" \
		build_number:"$(BUILD_NUMBER)" \
		beta_description:"$(BETA_DESCRIPTION)" \
		testers:"$(TESTERS)" \
		groups:"$(GROUPS)" \
		automatic_release:$(or $(AUTOMATIC_RELEASE),false) \
		submit_for_review:$(or $(SUBMIT_FOR_REVIEW),false)

release-new:
	$(FASTLANE) $(PLATFORM) release_new \
		create_app:$(or $(CREATE_APP),true) \
		scheme:"$(SCHEME)" \
		app_identifier:"$(APP_IDENTIFIER)" \
		app_name:"$(APP_NAME)" \
		sku:"$(SKU)" \
		language:"$(or $(LANGUAGE),en-US)" \
		version:"$(VERSION)" \
		build_number:"$(BUILD_NUMBER)" \
		beta_description:"$(BETA_DESCRIPTION)" \
		testers:"$(TESTERS)" \
		groups:"$(GROUPS)" \
		automatic_release:$(or $(AUTOMATIC_RELEASE),false) \
		submit_for_review:$(or $(SUBMIT_FOR_REVIEW),false)

metadata-only:
	$(FASTLANE) $(PLATFORM) metadata_only \
		app_identifier:"$(APP_IDENTIFIER)" \
		upload_metadata:$(or $(UPLOAD_METADATA),true) \
		upload_screenshots:$(or $(UPLOAD_SCREENSHOTS),true)

install-template:
	bash scripts/create_project.sh "$(TARGET_DIR)"
