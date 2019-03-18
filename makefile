server:
	bundle exec middleman server

build:
	bundle exec middleman build --build-dir docs
	touch docs/.nojekyll
