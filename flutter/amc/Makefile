LOCAL_PROPS := ../../local.properties
DART_DEFINES := dart_defines.json

# ../../local.properties から SUPABASE_* を dart_defines.json に書き出す
$(DART_DEFINES): $(LOCAL_PROPS)
	python3 -c "\
import re, json, sys; \
props = {}; \
[props.update({m.group(1): m.group(2)}) for line in open('$(LOCAL_PROPS)') if (m := re.match(r'^(SUPABASE_\w+)=(.+)', line.strip()))]; \
print(json.dumps(props, indent=2))" > $(DART_DEFINES)
	@echo "✓ $(DART_DEFINES) を生成しました"

gen-env: $(DART_DEFINES)

run: gen-env
	flutter run --dart-define-from-file=$(DART_DEFINES)

run-web: gen-env
	flutter run -d chrome --dart-define-from-file=$(DART_DEFINES)

run-android: gen-env
	flutter run -d 3B171FDJH0039F --dart-define-from-file=$(DART_DEFINES)

build-apk: gen-env
	flutter build apk --debug --dart-define-from-file=$(DART_DEFINES)

test:
	flutter test

analyze:
	flutter analyze lib/

.PHONY: gen-env run run-web run-android build-apk test analyze
