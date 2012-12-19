SRC = sprig.js
DST = "."

REPORTER = dot

all: sprig.min.js

test:
	@NODE_ENV=test ./node_modules/.bin/mocha \
		--reporter $(REPORTER)

test-browser:
	-@node_modules/.bin/coffee test/server test/browser.html

sprig.min.js:
	@node_modules/.bin/uglifyjs --no-mangle $(SRC)$< > $@
	@node -e "console.log('%sKB %s', (Math.round(require('fs').statSync('$(DST)/$@').size/1024)), '$(DST)/$@')"

docs: test-docs

test-docs:
	$(MAKE) test REPORTER=doc > docs/test.html

clean:
	rm sprig.min.js

.PHONY: test-cov test docs test-docs clean