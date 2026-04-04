## Summary

Describe the change in 1-3 sentences.

## Why

Explain the user-facing reason for this change.

## Validation

- [ ] `ruby -c ios-newapp-template/fastlane/Fastfile`
- [ ] `ruby -c ios-newapp-template/fastlane/Appfile`
- [ ] `bash -n ios-newapp-template/scripts/create_project.sh`
- [ ] `bash -n ios-newapp-template/scripts/replace_placeholders.sh`
- [ ] `cd ios-newapp-template && fastlane lanes`
- [ ] `make -C ios-newapp-template validate`

## Notes

Mention any documentation updates, behavior changes, or known limits.
