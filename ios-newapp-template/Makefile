FASTLANE ?= fastlane
PLATFORM ?= ios

.PHONY: help lanes validate precheck-assets local-build release-existing release-new testflight-only submit-review metadata-only install-template

help:
	@echo "Targets:"
	@echo "  make lanes"
	@echo "  make validate"
	@echo "  make precheck-assets"
	@echo "  make local-build SCHEME=MyApp EXPORT_METHOD=development"
	@echo "  make release-existing SCHEME=MyApp APP_IDENTIFIER=com.example.app"
	@echo "  make release-new SCHEME=MyApp APP_IDENTIFIER=com.example.app APP_NAME=MyApp SKU=myapp001"
	@echo "  make testflight-only SCHEME=MyApp APP_IDENTIFIER=com.example.app"
	@echo "  make submit-review APP_IDENTIFIER=com.example.app"
	@echo "  make metadata-only APP_IDENTIFIER=com.example.app"
	@echo "  make install-template TARGET_DIR=/path/to/project"

lanes:
	$(FASTLANE) lanes

validate:
	$(FASTLANE) $(PLATFORM) validate_setup

precheck-assets:
	$(FASTLANE) $(PLATFORM) precheck_assets

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

testflight-only:
	$(FASTLANE) $(PLATFORM) testflight_only \
		scheme:"$(SCHEME)" \
		app_identifier:"$(APP_IDENTIFIER)" \
		version:"$(VERSION)" \
		build_number:"$(BUILD_NUMBER)" \
		beta_description:"$(BETA_DESCRIPTION)" \
		testers:"$(TESTERS)" \
		groups:"$(GROUPS)" \
		distribute_external:$(or $(DISTRIBUTE_EXTERNAL),false)

submit-review:
	$(FASTLANE) $(PLATFORM) submit_review \
		app_identifier:"$(APP_IDENTIFIER)" \
		upload_metadata:$(or $(UPLOAD_METADATA),true) \
		upload_screenshots:$(or $(UPLOAD_SCREENSHOTS),true) \
		automatic_release:$(or $(AUTOMATIC_RELEASE),false)

metadata-only:
	$(FASTLANE) $(PLATFORM) metadata_only \
		app_identifier:"$(APP_IDENTIFIER)" \
		upload_metadata:$(or $(UPLOAD_METADATA),true) \
		upload_screenshots:$(or $(UPLOAD_SCREENSHOTS),true)

install-template:
	bash scripts/create_project.sh "$(TARGET_DIR)"
