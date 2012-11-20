SRC = lib/sprig.js
DST = "."

REPORTER = dot

all: sprig.js sprig.min.js

test:
	@NODE_ENV=test ./node_modules/.bin/mocha \
		--reporter $(REPORTER)

test-browser:
	@bin/test-server.js

test-cov: lib-cov
	@echo "  Generating test coverage report"
	@(MOCHA_COVERAGE=1 $(MAKE) test REPORTER=html-cov > coverage.html)
	@rm -R lib-cov
	@echo "  Done. Coverage report written to ./coverage.html"

lib-cov:
	jscoverage lib lib-cov

sprig.js: $(SRC)
	@cat $^ > $(DST)/$@
	@node -e "console.log('%sKB %s', (Math.round(require('fs').statSync('$(DST)/$@').size/1024)), '$(DST)/$@')"

sprig.min.js: sprig.js
	@node_modules/.bin/uglifyjs --no-mangle $(DST)/$< > $(DST)/$@
	@node -e "console.log('%sKB %s', (Math.round(require('fs').statSync('$(DST)/$@').size/1024)), '$(DST)/$@')"

docs: test-docs

test-docs:
	$(MAKE) test REPORTER=doc > docs/test.html

clean:
	rm -f sprig{,.min}.js
	rm -f coverage.html
	rm -Rf tmp
	rm -Rf lib-cov

.PHONY: test-cov test docs test-docs clean