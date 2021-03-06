.PHONY: help
help:
	$(info )
	$(info This makefile will help you build scout tool and generate events data)
	$(info )
	$(info Available options:)
	$(info )
	$(info - all:			Load events from all data sources and generate events)
	$(info - github:		Load data from github)
	$(info - stackoverflow: 	Load data from stackoverflow)
	$(info - mail:			Load data from mail archives)
	$(info - reddit:		Load data from reddit)
	$(info - gmane:			Load data from gmane)
	$(info - events:		Generate events JSON file)
	$(info - deploy:		Deploy JSON file to be shown in the web)
	$(info )
	@echo ""

SCOUT=PYTHONPATH=. bin/scout
DBNAME=scout
DBUSER=root
BACKENDS=github stackoverflow mail reddit gmane

#
# PYTHON
#

%.csv: %.csv.gz
	gunzip -c $^  > $@

%.json: %.json.gz
	gunzip -c $^  > $@

pep8:
	pep8 --exclude=VizGrimoireJS,./html .

github: data/GithubReposCentOS-P1.csv
	$(SCOUT) -d $(DBNAME) -u $(DBUSER) -b $@ -f $^

stackoverflow: data/StackOverFlowCentOS-P1.csv
	$(SCOUT) -d $(DBNAME) -u $(DBUSER) -b $@ -f $^

mail: data/MailmanOpenStackCentOS-P1.csv
	$(SCOUT) -d $(DBNAME) -u $(DBUSER) -b $@ -f $^

reddit: data/reddit_cache.json
	$(SCOUT) -d $(DBNAME) -u $(DBUSER) -b $@

gmane: data/gmane_cache.csv
	$(SCOUT) -d $(DBNAME) -u $(DBUSER) -b $@

.PHONY: events
events: cleandb github stackoverflow mail reddit gmane
	$(SCOUT) -j scout.json  -u root -d scout

#
# JAVASCRIPT
#

APP=html/browserng/app
APP_JS= $(APP)/app.js $(APP)/controllers.js $(APP)/scout $(APP)/lib/events.js

jshint:
	jshint html/app/lib/events.js

DEPLOY=/home/bitergia

# scout.json: events
deploy: scout.json
	cat $^ | python -m json.tool > /dev/null
	cd html && npm install && cd ..
	rm -rf $(DEPLOY)/app
	cp -a html/app $(DEPLOY)
	rm -rf $(DEPLOY)/app/bower_components
	cp -a html/bower_components $(DEPLOY)/app
	mkdir -p $(DEPLOY)/app/data/json
	cp $^ $(DEPLOY)/app/data/json

all: jshint pep8 cleandb $(BACKENDS) events deploy

cleandb:
	echo "drop database if exists $(DBNAME)" | mysql -u $(DBUSER)

.PHONY: clean
clean: cleandb
	rm -rf data/*.csv data/*.json scout.json
