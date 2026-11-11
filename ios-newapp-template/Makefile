FASTLANE ?= bundle exec fastlane
PLATFORM ?= ios

.PHONY: help lanes validate precheck-assets local-build release-existing release-new testflight-only submit-review metadata-only install-template

help:
	@echo "Targets: lanes validate precheck-assets local-build release-existing release-new testflight-only submit-review metadata-only"
	@echo "Configure fastlane/.env first. Optional overrides: SCHEME APP_IDENTIFIER VERSION BUILD_NUMBER"
	@echo "Metadata uploads: UPLOAD_METADATA=true; new app creation: CREATE_APP=true"

# Values are read as data by the recipe, including spaces and shell metacharacters.
export SCHEME APP_IDENTIFIER VERSION BUILD_NUMBER BETA_DESCRIPTION TESTERS GROUPS
export APP_NAME SKU LANGUAGE CREATE_APP EXPORT_METHOD DISTRIBUTE_EXTERNAL
export AUTOMATIC_RELEASE SUBMIT_FOR_REVIEW UPLOAD_METADATA UPLOAD_SCREENSHOTS

lanes:
	$(FASTLANE) lanes

validate:
	$(FASTLANE) $(PLATFORM) validate_setup

precheck-assets:
	$(FASTLANE) $(PLATFORM) precheck_assets strict:true

local-build release-existing release-new testflight-only submit-review metadata-only:
	@set -eu; set --; \
	for pair in scheme:SCHEME app_identifier:APP_IDENTIFIER version:VERSION build_number:BUILD_NUMBER \
	  beta_description:BETA_DESCRIPTION testers:TESTERS groups:GROUPS app_name:APP_NAME sku:SKU \
	  language:LANGUAGE create_app:CREATE_APP export_method:EXPORT_METHOD distribute_external:DISTRIBUTE_EXTERNAL \
	  automatic_release:AUTOMATIC_RELEASE submit_for_review:SUBMIT_FOR_REVIEW \
	  upload_metadata:UPLOAD_METADATA upload_screenshots:UPLOAD_SCREENSHOTS; do \
	  key=$${pair%%:*}; name=$${pair#*:}; value=$$(printenv "$$name" || true); \
	  if [ -n "$$value" ]; then set -- "$$@" "$$key:$$value"; fi; \
	done; \
	lane=$$(printf '%s' '$@' | tr '-' '_'); \
	exec $(FASTLANE) $(PLATFORM) "$$lane" "$$@"

install-template:
	bash scripts/create_project.sh "$(TARGET_DIR)"
