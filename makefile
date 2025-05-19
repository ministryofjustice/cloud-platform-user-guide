IMAGE := ghcr.io/ministryofjustice/tech-docs-github-pages-publisher@sha256:30d00879b5c82afa5d76264164db46189fa11d4358b37ca35b6a62e341d62bb7 # v5.1.0

# Use this to run a local instance of the documentation site, while editing
.PHONY: preview check

preview:
	docker run --rm \
		-v $$(pwd)/config:/app/config \
		-v $$(pwd)/source:/app/source \
		-p 4567:4567 \
		-it $(IMAGE) /scripts/preview.sh

deploy:
	docker run --rm \
		-v $$(pwd)/config:/app/config \
		-v $$(pwd)/source:/app/source \
		-it $(IMAGE) /scripts/deploy.sh

check:
	docker run --rm \
		-v $$(pwd)/config:/app/config \
		-v $$(pwd)/source:/app/source \
		-it $(IMAGE) /scripts/check-url-links.sh
