server:
	bundle exec middleman server

build:
	bundle exec middleman build --build-dir docs
	touch docs/.nojekyll
	echo user-guide.cloud-platform.service.justice.gov.uk > docs/CNAME
