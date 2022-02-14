.PHONY: build up down backup

# the docker images are tagged with the current git short sha
# timestamps are added to docker container names
SHELL=/bin/bash
DIR=$(shell pwd)
ACME_EMAIL=martin@hanewald.ai
CVAT_HOST=tg-annotation.hanewald.ai

export ACME_EMAIL
export CVAT_HOST

# build docker image
build:
	docker-compose -f docker-compose.yml -f docker-compose.https.yml -f docker-compose.share.yml -f docker-compose.dev.yml -f components/serverless/docker-compose.serverless.yml build

# compose up
up:
	docker-compose -f docker-compose.yml -f docker-compose.https.yml -f docker-compose.share.yml -f components/serverless/docker-compose.serverless.yml up -d

# compose down
down:
	docker-compose -f docker-compose.yml -f docker-compose.https.yml -f docker-compose.share.yml -f components/serverless/docker-compose.serverless.yml down
	docker volume rm cvat_cvat_share_2

stop:
	docker-compose -f docker-compose.yml -f docker-compose.https.yml -f docker-compose.share.yml -f components/serverless/docker-compose.serverless.yml stop

# https://openvinotoolkit.github.io/cvat/docs/administration/advanced/backup_guide/
backup:
	docker run --rm --name temp_backup --volumes-from cvat_db -v $(pwd)/backup:/backup ubuntu tar -cjvf /backup/cvat_db.tar.bz2 /var/lib/postgresql/data
	docker run --rm --name temp_backup --volumes-from cvat -v $(pwd)/backup:/backup ubuntu tar -cjvf /backup/cvat_data.tar.bz2 /home/django/data
	docker run --rm --name temp_backup --volumes-from cvat -v $(pwd)/backup:/backup ubuntu tar -cjvf /backup/cvat_keys.tar.bz2 /home/django/keys

restore:
	docker run --rm --name temp_backup --volumes-from cvat_db -v $(pwd)/backup:/backup ubuntu bash -c "cd /var/lib/postgresql/data && tar -xvf /backup/cvat_db.tar.bz2 --strip 4"
	docker run --rm --name temp_backup --volumes-from cvat -v $(pwd)/backup:/backup ubuntu bash -c "cd /home/django/data && tar -xvf /backup/cvat_data.tar.bz2 --strip 3"
	docker run --rm --name temp_backup --volumes-from cvat -v $(pwd)/backup:/backup ubuntu bash -c "cd /home/django/keys && tar -xvf /backup/cvat_keys.tar.bz2 --strip 3"

hrnet:
	nuctl deploy --project-name cvat \
		--path ./serverless/pytorch/saic-vul/hrnet/nuclio/ \
		--platform local


