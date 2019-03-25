IMAGE := cloud-platform-user-guide
DOMAIN := user-guide.cloud-platform.service.justice.gov.uk
VERSION := 1.0

.built-docker-image: Dockerfile Gemfile
	docker build -t $(IMAGE) .
	docker tag $(IMAGE) ministryofjustice/$(IMAGE):$(VERSION)
	docker push ministryofjustice/$(IMAGE):$(VERSION)
	touch .built-docker-image

server: .built-docker-image
	docker run \
		-p 4567:4567 \
		-v $$(pwd)/source:/app/source \
		-v $$(pwd)/docs:/app/docs \
		-it \
		$(IMAGE) bundle exec middleman server

build: .built-docker-image
	docker run \
		-v $$(pwd)/source:/app/source \
		-v $$(pwd)/docs:/app/docs \
		-it \
		$(IMAGE) bundle exec middleman build --build-dir docs
	touch docs/.nojekyll
	echo $(DOMAIN) > docs/CNAME
