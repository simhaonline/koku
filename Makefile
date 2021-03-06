# OpenShift settings
OC_VERSION	= v3.11
OC_DATA_DIR	= ${HOME}/.oc/openshift.local.data
OC_SOURCE	= registry.access.redhat.com/openshift3/ose

# PostgreSQL settings
PGSQL_VERSION   = 9.6

# Basic environment settings
PYTHON	= $(shell which python)
TOPDIR  = $(shell pwd)
PYDIR	= koku
APIDOC  = apidoc
KOKU_SERVER = $(shell echo "${KOKU_API_HOST:-localhost}")
KOKU_SERVER_PORT = $(shell echo "${KOKU_API_PORT:-8000}")
MASU_SERVER = $(shell echo "${MASU_SERVICE_HOST:-localhost}")
MASU_SERVER_PORT = $(shell echo "${MASU_SERVICE_PORT:-5000}")
DOCKER := $(shell which docker 2>/dev/null || which podman 2>/dev/null)

# Testing directories
TESTINGDIR = $(TOPDIR)/testing
PROVIDER_TEMP_DIR = $(TESTINGDIR)/pvc_dir
OCP_PROVIDER_TEMP_DIR = $(PROVIDER_TEMP_DIR)/insights_local

# How to execute Django's manage.py
DJANGO_MANAGE = DJANGO_READ_DOT_ENV_FILE=True $(PYTHON) $(PYDIR)/manage.py

# required OpenShift template parameters
# if a value is defined in a parameter file, we try to use that.
# otherwise, we use a default value
NAME = $(or $(shell grep -h '^NAME=' openshift/parameters/* 2>/dev/null | uniq | awk -F= '{print $$2}'), koku)
NAMESPACE = $(or $(shell grep -h '^[^\#]*NAMESPACE=' openshift/parameters/* 2>/dev/null | uniq | awk -F= '{print $$2}'), koku)

OC_TEMPLATE_DIR = $(TOPDIR)/openshift
OC_PARAM_DIR = $(OC_TEMPLATE_DIR)/parameters
OC_TEMPLATES = $(wildcard $(OC_TEMPLATE_DIR))


# Platform differences
#
# - Use 'sudo' on Linux
# - Don't use 'sudo' on MacOS
#
OS := $(shell uname)
ifeq ($(OS),Darwin)
	PREFIX	=
else
	PREFIX	= sudo
endif

help:
	@echo "Please use \`make <target>' where <target> is one of:"
	@echo ""
	@echo "--- General Commands ---"
	@echo "  clean                                 clean the project directory of any scratch files, bytecode, logs, etc"
	@echo "  help                                  show this message"
	@echo "  html                                  create html documentation for the project"
	@echo "  lint                                  run pre-commit against the project"
	@echo ""
	@echo "--- Commands using local services ---"
	@echo "  clear-testing                         Remove stale files/subdirectories from the testing directory."
	@echo "  create-test-customer                  create a test customer and tenant in the database"
	@echo "  create-test-customer-no-sources       create a test customer and tenant in the database without test sources"
	@echo "  create-large-ocp-source-config-file   create a config file for nise to generate a large data sample"
	@echo "                                          @param output_file_name - file name for output"
	@echo "                                          @param generator_config_file - (optional, default=default) config file for the generator"
	@echo "                                          @param generator_template_file - (optional) jinja2 template to render output"
	@echo "                                          @param generator_flags - (optional) additional cli flags and args"
	@echo "  large-ocp-source-testing              create a test OCP source "large_ocp_1" with a larger volume of data"
	@echo "                                          @param nise_config_dir - directory of nise config files to use"
	@echo "  load-test-customer-data               load test data for the default sources created in create-test-customer"
	@echo "                                          @param start - (optional) start date ex. 2019-08-02"
	@echo "                                          @param end - (optional) end date ex. 2019-12-5"
	@echo "  load-aws-org-unit-tree                inserts aws org tree into model and runs nise command to populate cost"
	@echo "                                          @param tree_yml - (optional) Tree yaml file. Default: 'scripts/aws_org_tree.yml'."
	@echo "                                          @param schema - (optional) schema name. Default: 'acct10001'."
	@echo "                                          @param nise_yml - (optional) Nise yaml file. Defaults to nise static yaml."
	@echo "  backup-local-db-dir                   make a backup copy PostgreSQL database directory (pg_data.bak)"
	@echo "  restore-local-db-dir                  overwrite the local PostgreSQL database directory with pg_data.bak"
	@echo "  collect-static                        collect static files to host"
	@echo "  make-migrations                       make migrations for the database"
	@echo "  requirements                          generate Pipfile.lock, RTD requirements and manifest for product security"
	@echo "  manifest                              create/update manifest for product security"
	@echo "  check-manifest                        check that the manifest is up to date"
	@echo "  remove-db                             remove local directory $(TOPDIR)/pg_data"
	@echo "  remove-test-db                        remove the django test db"
	@echo "  reset-db-statistics                   clear the pg_stat_statements statistics"
	@echo "  run-migrations                        run migrations against database"
	@echo "  serve                                 run the Django app on localhost"
	@echo "  shell                                 run the Django interactive shell"
	@echo "  shell-schema                          run the Django interactive shell with the specified schema"
	@echo "                                          @param schema - (optional) schema name. Default: 'acct10001'."
	@echo "  superuser                             create a Django super user"
	@echo "  unittest                              run unittests"
	@echo ""
	@echo "--- Commands using Docker Compose ---"
	@echo "  docker-up                            run docker-compose up --build -d"
	@echo "  docker-up-no-build                   run docker-compose up -d"
	@echo "  docker-up-koku                       run docker-compose up -d koku-server"
	@echo "                                         @param build : set to '--build' to build the container"
	@echo "  docker-up-db                         run database only"
	@echo "  docker-up-db-monitor                 run the database monitoring via grafana"
	@echo "                                         url:      localhost:3001"
	@echo "                                         user:     admin"
	@echo "                                         password: admin12"
	@echo "  docker-up-min                        run database, koku/masu servers and worker"
	@echo "  docker-down                          shut down all containers"
	@echo "  docker-rabbit                        run RabbitMQ container"
	@echo "  docker-reinitdb                      drop and recreate the database"
	@echo "  docker-reinitdb-with-sources         drop and recreate the database with fake sources"
	@echo "  docker-shell                         run Django and database containers with shell access to server (for pdb)"
	@echo "  docker-logs                          connect to console logs for all services"
	@echo "  docker-test-all                      run unittests"
	@echo "  docker-iqe-local-hccm                create container based off local hccm plugin. Requires env 'HCCM_PLUGIN_PATH'"
	@echo "                                          @param iqe_cmd - (optional) Command to run. Defaults to 'bash'."
	@echo "  docker-iqe-smokes-tests              run smoke tests"
	@echo "  docker-iqe-api-tests                 run api tests"
	@echo "  docker-iqe-vortex-tests              run vortex tests"
	@echo ""
	@echo "--- Commands using an OpenShift Cluster ---"
	@echo "  oc-forward-ports                      port forward the DB to localhost"
	@echo "  oc-login-dev                          login to an openshift cluster as 'developer'"
	@echo "  oc-reinit                             remove existing app and restart app in initialized openshift cluster"
	@echo "  oc-run-migrations                     run Django migrations in the Openshift DB"
	@echo "  oc-stop-forwarding-ports              stop port forwarding the DB to localhost"
	@echo ""
	@echo "--- Create Sources ---"
	@echo "  ocp-source-from-yaml                  Create ocp source using a yaml file."
	@echo "      cluster_id=<cluster_name>           @param - Required. The name of your cluster (ex. my-ocp-cluster-0)"
	@echo "      srf_yaml=<filename>                 @param - Required. Path of static-report-file yaml (ex. '/ocp_static_report.yml')"
	@echo "      ocp_name=<source_name>              @param - Required. The name of the source. (ex. 'OCPsource')"
	@echo "  aws-source                            Create aws source using environment variables"
	@echo "      aws_name=<source_name>              @param - Required. Name of the source"
	@echo "      bucket=<bucket_name>                @param - Required. Name of the bucket"

### General Commands ###

clean:
	git clean -fdx -e .idea/ -e *env/ -e .env

html:
	@cd docs; $(MAKE) html

lint:
	pre-commit run --all-files

clear-testing:
	$(PYTHON) $(TOPDIR)/scripts/clear_testing.py -p $(TOPDIR)/testing

create-test-customer: run-migrations docker-up-koku
	$(PYTHON) $(TOPDIR)/scripts/create_test_customer.py || echo "WARNING: create_test_customer failed unexpectedly!"

create-test-customer-no-sources: run-migrations docker-up-koku
	$(PYTHON) $(TOPDIR)/scripts/create_test_customer.py --no-sources --bypass-api || echo "WARNING: create_test_customer failed unexpectedly!"

load-test-customer-data:
	$(TOPDIR)/scripts/load_test_customer_data.sh $(TOPDIR) $(start) $(end)

load-aws-org-unit-tree:
	@if [ $(shell $(PYTHON) -c 'import sys; print(sys.version_info[0])') = '3' ] ; then \
		$(PYTHON) $(TOPDIR)/scripts/insert_aws_org_tree.py tree_yml=$(tree_yml) schema=$(schema) nise_yml=$(nise_yml) ; \
	else \
		echo "This make target requires python3." ; \
	fi

collect-static:
	$(DJANGO_MANAGE) collectstatic --no-input

make-migrations:
	$(DJANGO_MANAGE) makemigrations api reporting reporting_common cost_models

remove-db:
	$(PREFIX) rm -rf $(TOPDIR)/pg_data

remove-test-db:
	@PGPASSWORD=$$DATABASE_PASSWORD psql -h $$POSTGRES_SQL_SERVICE_HOST \
                                         -p $$POSTGRES_SQL_SERVICE_PORT \
                                         -d $$DATABASE_NAME \
                                         -U $$DATABASE_USER \
                                         -c "DROP DATABASE test_$$DATABASE_NAME;" >/dev/null
	@echo "Test DB (test_$$DATABASE_NAME) has been removed."

reset-db-statistics:
	@PGPASSWORD=$$DATABASE_PASSWORD psql -h $$POSTGRES_SQL_SERVICE_HOST \
                                         -p $$POSTGRES_SQL_SERVICE_PORT \
                                         -d $$DATABASE_NAME \
                                         -U $$DATABASE_USER \
                                         -c "select pg_stat_statements_reset();" >/dev/null
	@echo "Statistics have been reset"

requirements:
	pipenv lock
	pipenv lock -r > docs/rtd_requirements.txt
	python scripts/create_manifest.py

manifest:
	python scripts/create_manifest.py

check-manifest:
	.github/scripts/check_manifest.sh

run-migrations:
	$(DJANGO_MANAGE) migrate_schemas --executor=parallel

serve:
	$(DJANGO_MANAGE) runserver

shell:
	$(DJANGO_MANAGE) shell

shell-schema: schema := acct10001
shell-schema:
	$(DJANGO_MANAGE) tenant_command shell --schema=$(schema)

unittest:
	$(DJANGO_MANAGE) test $(PYDIR) -v 2

superuser:
	$(DJANGO_MANAGE) createsuperuser

####################################
# Commands using OpenShift Cluster #
####################################

oc-forward-ports: oc-stop-forwarding-ports
	@oc port-forward $$(oc get pods -o jsonpath='{.items[?(.status.phase=="Running")].metadata.name}' -l name=koku-db) 15432:5432 >/dev/null 2>&1 &

oc-login-dev:
	oc login -u developer --insecure-skip-tls-verify=true localhost:8443

oc-make-migrations: oc-forward-ports
	sleep 1
	$(DJANGO_MANAGE) makemigrations api reporting reporting_common cost_models
	$(MAKE) oc-stop-forwarding-ports

oc-run-migrations: oc-forward-ports
	sleep 1
	$(DJANGO_MANAGE) migrate_schemas
	$(MAKE) oc-stop-forwarding-ports

oc-stop-forwarding-ports:
	@kill -HUP $$(ps -eo pid,command | grep "oc port-forward" | grep -v grep | awk '{print $$1}') 2>/dev/null || true

oc-delete-e2e:
	oc delete project/hccm project/buildfactory project/secrets

###############################
### Docker-compose Commands ###
###############################

docker-down:
	docker-compose down -v
	$(PREFIX) make clear-testing

docker-down-db:
	docker-compose rm -s -v -f db

docker-logs:
	docker-compose logs -f koku-server koku-worker masu-server

docker-presto-logs:
	docker-compose -f ./testing/compose_files/docker-compose-presto.yml logs -f

docker-rabbit:
	docker-compose up -d rabbit

docker-reinitdb: docker-down-db remove-db docker-up-db run-migrations docker-restart-koku create-test-customer-no-sources
	@echo "Local database re-initialized with a test customer."

docker-reinitdb-with-sources: docker-down-db remove-db docker-up-db run-migrations docker-restart-koku create-test-customer
	@echo "Local database re-initialized with a test customer and sources."

docker-shell:
	docker-compose run --service-ports koku-server

docker-test-all:
	docker-compose -f koku-test.yml up --build

docker-restart-koku:
	@if [ -n "$$($(DOCKER) ps -q -f name=koku_server)" ] ; then \
         docker-compose restart koku-server masu-server koku-worker koku-beat koku-listener ; \
         make _koku-wait ; \
         echo " koku is available" ; \
     else \
         make docker-up-koku ; \
     fi

docker-up-koku:
	@if [ -z "$$($(DOCKER) ps -q -f name=koku_server)" ] ; then \
         echo "Starting koku_server ..." ; \
         docker-compose up $(build) -d koku-server ; \
         make _koku-wait ; \
     fi
	@echo " koku is available!"

_koku-wait:
	@echo "Waiting on koku status: "
	@until ./scripts/check_for_koku_server.sh $${KOKU_API_HOST:-localhost} $${API_PATH_PREFIX:-/api/cost-management} $${KOKU_API_PORT:-8000} >/dev/null 2>&1 ; do \
         printf "." ; \
         sleep 1 ; \
     done

docker-up:
	docker-compose up --build -d

docker-up-no-build:
	docker-compose up -d

docker-up-min:
	docker-compose up --build -d db redis koku-server masu-server koku-worker

docker-up-min-presto: docker-presto-up docker-up-min

docker-up-db:
	docker-compose up -d db
	@until pg_isready -h $${POSTGRES_SQL_SERVICE_HOST:-localhost} -p $${POSTGRES_SQL_SERVICE_PORT:-15432} >/dev/null ; do \
	    printf '.'; \
	    sleep 0.5 ; \
    done
	@echo ' PostgreSQL is available!'

docker-up-db-monitor:
	docker-compose up --build -d grafana
	@echo "Monitor is up at localhost:3001  User=admin  Password=admin12"

_set-test-dir-permissions:
	@$(PREFIX) chmod -R o+rw,g+rw ./testing
	@$(PREFIX) find ./testing -type d -exec chmod o+x,g+x {} \;

docker-iqe-local-hccm: docker-reinitdb _set-test-dir-permissions clear-testing
	./testing/run_local_hccm.sh $(iqe_cmd)

docker-iqe-smokes-tests: docker-reinitdb _set-test-dir-permissions clear-testing
	./testing/run_smoke_tests.sh

docker-iqe-api-tests: docker-reinitdb _set-test-dir-permissions clear-testing
	./testing/run_api_tests.sh

docker-iqe-vortex-tests: docker-reinitdb _set-test-dir-permissions clear-testing
	./testing/run_vortex_api_tests.sh

docker-metastore-setup:
	@cp -fr deploy/metastore/ testing/metastore/
	@cp -fr deploy/hadoop/ testing/hadoop/
	@sed -i "" 's/s3path/$(shell echo $(or $(S3_BUCKET_NAME),metastore))/g' testing/hadoop/hadoop-config/core-site.xml
	@sed -i "" 's/s3path/$(shell echo $(or $(S3_BUCKET_NAME),metastore))/g' testing/metastore/hive-config/hive-site.xml
	@sed -i "" 's%s3endpoint%$(shell echo $(or $(S3_ENDPOINT),localhost))%g' testing/metastore/hive-config/hive-site.xml
	@sed -i "" 's/s3access/$(shell echo $(or $(S3_ACCESS_KEY),localhost))/g' testing/metastore/hive-config/hive-site.xml
	@sed -i "" 's/s3secret/$(shell echo $(or $(S3_SECRET),localhost))/g' testing/metastore/hive-config/hive-site.xml

docker-presto-setup:
	@cp -fr deploy/presto/ testing/presto/
	@cp -fr deploy/hadoop/ testing/hadoop/
	@sed -i "" 's/s3path/$(shell echo $(or $(S3_BUCKET_NAME),metastore))/g' testing/hadoop/hadoop-config/core-site.xml

docker-presto-cleanup:
	@rm -fr testing/parquet_data testing/hadoop testing/metastore testing/presto

docker-presto-up: docker-metastore-setup docker-presto-setup
	docker-compose -f ./testing/compose_files/docker-compose-presto.yml up -d

docker-presto-down: docker-presto-cleanup
	docker-compose -f ./testing/compose_files/docker-compose-presto.yml down

### Source targets ###
ocp-source-from-yaml:
#parameter validation
ifndef cluster_id
	$(error param cluster_id is not set)
endif
ifndef srf_yaml
	$(error param srf_yaml is not set)
endif
ifndef ocp_name
	$(error param ocp_name is not set)
endif
	(command -v nise > /dev/null 2>&1) || (echo 'nise is not installed, please install nise.' && exit 1 )
	mkdir -p testing/pvc_dir/insights_local
	nise report ocp --ocp-cluster-id $(cluster_id) --insights-upload testing/pvc_dir/insights_local --static-report-file $(srf_yaml)
	curl -d '{"name": "$(ocp_name)", "source_type": "OCP", "authentication": {"credentials": {"cluster_id": "$(cluster_id)"}}}' -H "Content-Type: application/json" -X POST http://0.0.0.0:8000/api/cost-management/v1/sources/
# From here you can hit the http://127.0.0.1:5000/api/cost-management/v1/download/ endpoint to start running masu.
# After masu has run these endpoints should have data in them: (v1/reports/openshift/memory, v1/reports/openshift/compute/, v1/reports/openshift/volumes/)

aws-source:
ifndef aws_name
	$(error param aws_name is not set)
endif
ifndef bucket
	$(error param bucket is not set)
endif
	(printenv AWS_RESOURCE_NAME > /dev/null 2>&1) || (echo 'AWS_RESOURCE_NAME is not set in .env' && exit 1)
	curl -d '{"name": "$(aws_name)", "source_type": "AWS", "authentication": {"credentials": {"role_arn":"${AWS_RESOURCE_NAME}"}}, "billing_source": {"data_source": {"bucket": "$(bucket)"}}}' -H "Content-Type: application/json" -X POST http://0.0.0.0:8000/api/cost-management/v1/sources/

###################################################
#  This section is for larger data volume testing
###################################################

create-large-ocp-source-config-file:
ifndef output_file_name
	$(error param output_file_name is not set)
endif
ifdef generator_template_file
	@nise yaml ocp -c $(or $(generator_config_file), default) -t $(generator_template_file) -o $(output_file_name) $(generator_flags)
else
	@nise yaml ocp -c $(or $(generator_config_file), default) -o $(output_file_name) $(generator_flags)
endif


create-large-ocp-source-testing-files:
ifndef nise_config_dir
	$(error param nise_config_dir is not set)
endif
	make purge-large-testing-ocp-files
	@for FILE in $(foreach f, $(wildcard $(nise_config_dir)/*.yml), $(f)) ; \
    do \
        make ocp-source-from-yaml cluster_id=large_ocp_1 srf_yaml=$$FILE ocp_name=large_ocp_1 ; \
	done

import-large-ocp-source-testing-costmodel:
	curl --header 'Content-Type: application/json' \
	     --request POST \
	     --data '{"name": "Cost Management OpenShift Cost Model", "description": "A cost model of on-premises OpenShift clusters.", "source_type": "OCP", "source_uuids": $(shell make -s find-large-testing-source-uuid), "rates": [{"metric": {"name": "cpu_core_usage_per_hour"}, "tiered_rates": [{"unit": "USD", "value": 0.007, "usage_start": null, "usage_end": null}]}, {"metric": {"name": "node_cost_per_month"}, "tiered_rates": [{"unit": "USD", "value": 0.2, "usage_start": null, "usage_end": null}]}, {"metric": {"name": "cpu_core_request_per_hour"}, "tiered_rates": [{"unit": "USD", "value": 0.2, "usage_start": null, "usage_end": null}]}, {"metric": {"name": "memory_gb_usage_per_hour"}, "tiered_rates": [{"unit": "USD", "value": 0.009, "usage_start": null, "usage_end": null}]}, {"metric": {"name": "memory_gb_request_per_hour"}, "tiered_rates": [{"unit": "USD", "value": 0.05, "usage_start": null, "usage_end": null}]}, {"metric": {"name": "storage_gb_usage_per_month"}, "tiered_rates": [{"unit": "USD", "value": 0.01, "usage_start": null, "usage_end": null}]}, {"metric": {"name": "storage_gb_request_per_month"}, "tiered_rates": [{"unit": "USD", "value": 0.01, "usage_start": null, "usage_end": null}]}]}' \
	     http://$(KOKU_SERVER):$(KOKU_SERVER_PORT)/api/cost-management/v1/cost-models/

import-large-ocp-source-testing-data:
	curl --request GET http://$(MASU_SERVER):$(MASU_SERVER_PORT)/api/cost-management/v1/download/

# Create a large volume of data for a test OCP source
# Will create the files, add the cost model and process the data
large-ocp-source-testing:
ifndef nise_config_dir
	$(error param nise_config_dir is not set)
endif
	make create-large-ocp-source-testing-files nise_config_dir="$(nise_config_dir)"
	make import-large-ocp-source-testing-costmodel
	make import-large-ocp-source-testing-data

# Delete the testing large ocp source local files
purge-large-testing-ocp-files:
	rm -rf $(OCP_PROVIDER_TEMP_DIR)/large_ocp_1

# Delete *ALL* local testing files
purge-all-testing-ocp-files:
	rm -rf $(OCP_PROVIDER_TEMP_DIR)/*

# currently locked to the large ocp source
find-large-testing-source-uuid:
	@curl "http://$(KOKU_SERVER):$(KOKU_SERVER_PORT)/api/cost-management/v1/sources/?name=large_ocp_1" | python3 -c "import sys, json; data_list=json.load(sys.stdin)['data']; print([data['uuid'] for data in data_list if data['type']=='OCP']);" | tr "'" '"'


# Dump local database
dump-local-db:
ifndef dump_outfile
	$(error param dump_outfile not set)
endif
	@if [ ! -x "$(shell which pg_dump)" ]; then \
        echo "ERROR :: Cannot find 'pg_dump' program" >&2 ; \
        false ; \
    else \
	    PGPASSWORD=$$DATABASE_PASSWORD pg_dump -h $$POSTGRES_SQL_SERVICE_HOST \
                                               -p $$POSTGRES_SQL_SERVICE_PORT \
                                               -d $$DATABASE_NAME \
                                               -U $$DATABASE_USER \
                                               --clean --if-exists --verbose \
                                               --file=$(dump_outfile) ; \
    fi


# Restore local database
load-local-db:
ifndef dump_outfile
	$(error param dump_outfile not set)
endif
	@if [ ! -x "$(shell which psql)" ]; then \
	    echo "ERROR :: Cannot find 'psql' program" >&2 ; \
		false ; \
	else \
	    PGPASSWORD=$$DATABASE_PASSWORD psql -h $$POSTGRES_SQL_SERVICE_HOST \
                                            -p $$POSTGRES_SQL_SERVICE_PORT \
                                            -d $$DATABASE_NAME \
                                            -U $$DATABASE_USER \
                                            --file=$(dump_outfile) ; \
	fi


backup-local-db-dir:
	docker-compose stop db
	@cd $(TOPDIR)
	@echo "Copying pg_data to pg_data.bak..."
	@$(PREFIX) cp -rp ./pg_data ./pg_data.bak
	@cd - >/dev/null
	docker-compose start db


restore-local-db-dir:
	@cd $(TOPDIR)
	@if [ -d ./pg_data.bak ] ; then \
	    docker-compose stop db ; \
	    echo "Removing pg_data..." ; \
	    $(PREFIX) rm -rf ./pg_data ; \
	    echo "Renaming pg_data.bak to pg_data..." ; \
	    $(PREFIX) mv -f ./pg_data.bak ./pg_data ; \
	    docker-compose start db ; \
	    echo "NOTE :: Migrations may need to be run." ; \
	else \
	    echo "NOTE :: There is no pg_data.bak dir to restore from." ; \
	fi
	@cd - >/dev/null
