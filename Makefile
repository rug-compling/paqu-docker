
include Makefile.cfg

ifeq ($(findstring rootless, $(shell docker info --format '{{.SecurityOptions}}')), )
DOCKERARGS = --net=host
else
DOCKERARGS = --volume=/tmp/.X11-unix/:/tmp/.X11-unix/
endif

# parallel execution werkt niet met -i voor docker
# zonder -i voor docker zijn processen in docker niet te onderbreken
.NOTPARALLEL:

.PHONY: help
help:
	@echo Beschikbare targets voor make:
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[34m%-8s\033[0m %s\n", $$1, $$2}'

shell:
	docker run $(DOCKERARGS) --rm -i -t \
		-e DISPLAY \
		-v $(PWD)/paqu-in-docker/build/opt:/opt \
		-v $(PWD)/src:/src \
		-v $(PWD)/tmp:/tmp \
		-v $(PWD)/work:/work \
		localhost/paqu-devel:latest

distclean:
	if [ -d work/cache/go ]; then chmod -cR u+w work/cache/go; fi
	rm -fr \
		paqu-in-docker/build/opt \
		work

step0:	## deze repo bijwerken
	git pull

step1:	## maak/update het image dat in de volgende stappen gebruikt wordt
	build/build.sh

step2:	step1 ## installeer DbXML
	#if [ ! -f src/dbxml-6.1.4.tar.gz ]; \
	#	then cp /net/corpora/docker/alpino/src/dbxml-6.1.4.tar.gz src; fi
	docker run $(DOCKERARGS) --rm -i -t \
		-v $(PWD)/paqu-in-docker/build/opt:/opt \
		-v $(PWD)/scripts:/scripts \
		-v $(PWD)/work/dbxml:/dbxml \
		localhost/paqu-devel:latest \
		/scripts/install-dbxml.sh

step3:	step2 ## installeer PaQu
	docker run $(DOCKERARGS) --rm -i -t \
		-v $(PWD)/paqu-in-docker/build/opt:/opt \
		-v $(PWD)/scripts:/scripts \
		-v $(PWD)/work/cache:/cache \
		-v $(PWD)/work/paqu:/paqu \
		localhost/paqu-devel:latest \
		/scripts/install-paqu.sh

step4:	step2 ## installeer extra binary's
	docker run $(DOCKERARGS) --rm -i -t \
		-v $(PWD)/paqu-in-docker/build/opt:/opt \
		-v $(PWD)/scripts:/scripts \
		-v $(PWD)/src:/src \
		-v $(PWD)/work/cache:/cache \
		-v $(PWD)/work/paqu:/paqu \
		localhost/paqu-devel:latest \
		make -C /src

step5:	paqu-in-docker/build/alpino.tar.gz  ## zet Alpino klaar

step6:	step3 step4 paqu-in-docker/build/cdb.dactx  ## zet corpora klaar

step8:	step3 step4 step5 step6 ## maak image van PaQu in Docker
	cd paqu-in-docker/build && ./build.sh

step9:	step8 ## push image van PaQu in Docker naar de server
	@echo
	@echo -e '\e[1mVergeet niet af en toe oude versies te verwijderen, anders is ons quotum op\e[0m'
	@echo https://registry.webhosting.rug.nl/harbor/projects/57/repositories/paqu/artifacts-tab
	@echo
	cd paqu-in-docker/build && ./push.sh

paqu-in-docker/build/alpino.tar.gz: $(ALPINO_TGZ)
	rm -fr Alpino tmp.tgz
	tar xzf $<
	tar vczf tmp.tgz \
		Alpino/version \
	        Alpino/Generation/fluency/*.fsa \
	        Alpino/Generation/fluency/*.tpl \
		Alpino/Grammar/*.fsa \
	        Alpino/Hdrug/Tcl \
	        Alpino/Lexicon/*.fsa \
	        Alpino/Names/*.fsa \
	        Alpino/PosTagger/MODELS \
	        Alpino/Tokenization \
	        Alpino/TreebankTools \
	        Alpino/bin \
	        Alpino/create_bin \
	        Alpino/fadd/*.so \
	        Alpino/unix/*.so*
	mv tmp.tgz $@
	rm -fr Alpino

paqu-in-docker/build/cdb.dactx: paqu-in-docker/build/cdb.dact
	rm -f $@.tmp
	docker run $(DOCKERARGS) --rm -i -t \
		-v $(PWD)/paqu-in-docker/build/opt:/opt \
		-v $(PWD)/paqu-in-docker/build:/tmp \
		localhost/paqu-devel:latest \
		/opt/bin/pqdactx /tmp/cdb.dact /tmp/cdb.dactx.tmp
	mv $@.tmp $@

paqu-in-docker/build/cdb.dact: $(CDB_TGZ)
	@echo
	@echo -e '\e[1mNieuwste versie hier te downloaden:\e[0m'
	@echo https://www.let.rug.nl/vannoord/treebanks/
	@echo
	rm -fr cdb
	tar xzf $(CDB_TGZ)
	date -r `ls -t cdb/*.xml | head -n 1` +%Y-%m-%d > paqu-in-docker/build/cdbdate
	cp paqu-in-docker/build/cdbdate paqu-in-docker/build/cdbversion
	docker run $(DOCKERARGS) --rm -i -t \
		-v $(PWD)/cdb:/tmp \
		-v $(PWD)/paqu-in-docker/build:/build \
		-v $(PWD)/paqu-in-docker/build/opt:/opt \
		-v $(PWD)/scripts:/scripts \
		localhost/paqu-devel:latest \
		/scripts/install-cdb.sh
	rm -fr cdb
