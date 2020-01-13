IMAGE := cloud-platform-user-guide
DOMAIN := user-guide.cloud-platform.service.justice.gov.uk
VERSION := 1.6  # Change this in .circleci/config.yml if you update it here

.built-docker-image: Dockerfile Gemfile Gemfile.lock
	docker build -t $(IMAGE) .
	touch .built-docker-image

Gemfile.lock: Dockerfile.gemfile-lock
	docker build -t temp -f Dockerfile.gemfile-lock .
	docker run \
		-v $$(pwd):/app \
		-w /app \
		-it \
		temp bundle install

docker-push: .built-docker-image
	docker tag $(IMAGE) ministryofjustice/$(IMAGE):$(VERSION)
	docker push ministryofjustice/$(IMAGE):$(VERSION)

server:
	docker run \
		-p 4567:4567 \
		-v $$(pwd)/source:/app/source \
		-v $$(pwd)/docs:/app/docs \
		-v $$(pwd)/config:/app/config \
		-it \
		ministryofjustice/$(IMAGE):$(VERSION) bundle exec middleman server

# The CircleCI build pipeline does this, so it should never
# be necessary to run this task. I'm leaving it here for
# reference, and in case we ever need to push changes
# manually.
build: .built-docker-image
	docker run \
		-v $$(pwd)/source:/app/source \
		-v $$(pwd)/docs:/app/docs \
		-v $$(pwd)/config:/app/config \
		-it \
		$(IMAGE) bundle exec middleman build --build-dir docs
	touch docs/.nojekyll
	echo $(DOMAIN) > docs/CNAME

test: 
	htmlproofer --allow-hash-href ./docs

# Convert the user guide to a folder-based structure
convert:
	mv source/getting-help.html.md.erb source/documentation/reference/
	rm source/documentation/*/index.md
	find source/documentation/ -name '*.md' | xargs -n 1 bin/convert-files-for-new-structure.rb
	find source/documentation/ -name '*.md' | xargs rm
	rm source/concepts.html.md.erb
	rm source/reference.html.md.erb
	rm source/tasks.html.md.erb
	echo >> source/index.html.md.erb
	echo >> source/index.html.md.erb
	find source/documentation -name '*.html.md.erb' | xargs -n 1 bin/add-to-index.rb

