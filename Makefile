.PHONY: run test build

run:
	@bundle exec jekyll s

build:
	@bundle exec jekyll b -d _site

test:
	@bundle exec htmlproofer "_site" \
               \-\-disable-external=true \
               \-\-ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/0.0.0.0/,/^http:\/\/localhost/"
