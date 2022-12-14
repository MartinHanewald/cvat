.PHONY: build up down backup

# the docker images are tagged with the current git short sha
# timestamps are added to docker container names
SHELL=/bin/bash
DIR=$(shell pwd)
ACME_EMAIL=martin@hanewald.ai
CVAT_HOST=tg-annotation.hanewald.ai
RESULTVIEWER_HOST=tg-resultviewer.hanewald.ai
BACKUP_DIR=/home/martin/GDrive/cvat_backup/

export ACME_EMAIL
export CVAT_HOST
export RESULTVIEWER_HOST

# build docker image
build:
	docker-compose -f docker-compose.yml -f docker-compose.https.yml -f docker-compose.share.yml -f docker-compose.dev.yml -f components/serverless/docker-compose.serverless.yml build

# compose up
up:
	docker-compose -f docker-compose.yml -f docker-compose.https.yml -f docker-compose.share.yml -f components/serverless/docker-compose.serverless.yml -f ../tg-poc-resultviewer/docker-compose.yml up -d --force-recreate

# compose down
down:
	docker-compose -f docker-compose.yml -f docker-compose.https.yml -f docker-compose.share.yml -f components/serverless/docker-compose.serverless.yml -f ../tg-poc-resultviewer/docker-compose.yml down
	docker volume rm cvat_cvat_share_2

stop:
	docker-compose -f docker-compose.yml -f docker-compose.https.yml -f docker-compose.share.yml -f components/serverless/docker-compose.serverless.yml -f ../tg-poc-resultviewer/docker-compose.yml stop

# https://openvinotoolkit.github.io/cvat/docs/administration/advanced/backup_guide/
backup_files:
	docker run --rm --name temp_backup --volumes-from cvat_db -v $(BACKUP_DIR):/backup ubuntu tar -cjvf /backup/cvat_db.tar.bz2 /var/lib/postgresql/data
	docker run --rm --name temp_backup --volumes-from cvat -v $(BACKUP_DIR):/backup ubuntu tar -cjvf /backup/cvat_data.tar.bz2 /home/django/data
	docker run --rm --name temp_backup --volumes-from cvat -v $(BACKUP_DIR):/backup ubuntu tar -cjvf /backup/cvat_keys.tar.bz2 /home/django/keys

restore_files:
	docker run --rm --name temp_backup --volumes-from cvat_db -v $(BACKUP_DIR):/backup ubuntu bash -c "cd /var/lib/postgresql/data && tar -xvf /backup/cvat_db.tar.bz2 --strip 4"
	docker run --rm --name temp_backup --volumes-from cvat -v $(BACKUP_DIR):/backup ubuntu bash -c "cd /home/django/data && tar -xvf /backup/cvat_data.tar.bz2 --strip 3"
	docker run --rm --name temp_backup --volumes-from cvat -v $(BACKUP_DIR):/backup ubuntu bash -c "cd /home/django/keys && tar -xvf /backup/cvat_keys.tar.bz2 --strip 3"

hrnet:
	nuctl deploy --project-name cvat \
		--path ./serverless/pytorch/saic-vul/hrnet/nuclio/ \
		--platform local

backup: down backup_files up

test:
	echo $(BACKUP_DIR)

manifest:
	docker run -it -u root --entrypoint bash -v /home/martin/cvat/manifest:/tmp/manifest:rw -v /home/martin/GDrive:/home/django/share:ro cvat/server -c "pip3 install -r utils/dataset_manifest/requirements.txt && python3 utils/dataset_manifest/create.py --output-dir /tmp/manifest/ /home/django/share/consolidated/data"


# add phony
.PHONY: build up down backup_files restore_files backup test manifest