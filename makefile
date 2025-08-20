.PHONY: package preview

IMAGE_NAME ?= ghcr.io/ministryofjustice/tech-docs-github-pages-publisher@sha256:30d00879b5c82afa5d76264164db46189fa11d4358b37ca35b6a62e341d62bb7

package:
	docker run --rm \
	    --name tech-docs-github-pages-publisher \
	    --volume $(PWD)/config:/tech-docs-github-pages-publisher/config \
		--volume $(PWD)/source:/tech-docs-github-pages-publisher/source \
		$(IMAGE_NAME) \
		/usr/local/bin/package

preview:
	docker run -it --rm \
	    --name tech-docs-github-pages-publisher-preview \
	    --volume $(PWD)/config:/tech-docs-github-pages-publisher/config \
		--volume $(PWD)/source:/tech-docs-github-pages-publisher/source \
		--publish 4567:4567 \
		$(IMAGE_NAME) \
		/usr/local/bin/preview
