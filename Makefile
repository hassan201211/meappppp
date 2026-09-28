NAME := SYSTORE
SCHEME := Feather
PLATFORMS := iphoneos

CERT_JSON_URL := https://backloop.dev/pack.json

.PHONY: all clean deps $(PLATFORMS)

all: $(PLATFORMS)

clean:
	rm -rf build_temp packages Payload _build

deps:
	rm -rf deps || true
	mkdir -p deps
	curl -fsSL "$(CERT_JSON_URL)" -o cert.json
	jq -r '.cert' cert.json > deps/server.crt
	jq -r '.key1, .key2' cert.json > deps/server.pem
	jq -r '.info.domains.commonName' cert.json > deps/commonName.txt

$(PLATFORMS): deps
	rm -rf _build build_temp packages
	mkdir -p _build/Payload packages

	@set -e; \
	xcodebuild \
		-project Feather.xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination "generic/platform=iOS" \
		-derivedDataPath build_temp \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		IPHONEOS_DEPLOYMENT_TARGET=15.0; \
	\
	echo "🔍 جاري البحث عن ملف التطبيق..."; \
	APP_PATH=$$(find . -name "Feather.app" -type d | grep -v "Payload" | head -n 1); \
	if [ -z "$$APP_PATH" ]; then \
		echo "❌ خطأ: لم يتم العثور على التطبيق!"; \
		exit 1; \
	fi; \
	echo "✅ تم العثور على التطبيق في المسار: $$APP_PATH"; \
	\
	cp -R "$$APP_PATH" _build/Payload/Feather.app; \
	chmod -R 0755 _build/Payload/Feather.app; \
	codesign --force --sign - --timestamp=none _build/Payload/Feather.app; \
	cp deps/* _build/Payload/Feather.app/ || true; \
	\
	ditto -c -k --sequesterRsrc --keepParent _build/Payload "packages/$(NAME).ipa"; \
	echo "🎉 تم إنشاء ملف الـ IPA بنجاح!"
