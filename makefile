IMAGE := cloud-platform-user-guide
DOMAIN := user-guide.cloud-platform.service.justice.gov.uk
VERSION := 1.2

.built-docker-image: Dockerfile Gemfile
	docker build -t $(IMAGE) .
	touch .built-docker-image

docker-push: .built-docker-image
	docker tag $(IMAGE) ministryofjustice/$(IMAGE)
	docker push ministryofjustice/$(IMAGE)

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
