#!/bin/bash

export LOGIN="paqu:paqu@tcp($MYSQL_PORT_3306_TCP_ADDR:$MYSQL_PORT_3306_TCP_PORT)/paqu"

case "$1" in

    serve|pqserve)
	cd /mod/data

	echo Wachten tot MySQL beschikbaar is > message
	/mod/tools/dbwait &> message.err
	if [ $? != 0 ]
	then
	    touch pqserve.log
	    exit
	fi
	rm message.err

	if [ "`/mod/tools/corpustest alpinotreebank`" = "ok" ]
	then
	    echo De database wordt bijgewerkt naar de huidige versie > message
	    pqupgrade
	else
	    mkdir -p /mod/data/data
	    echo De database wordt klaargemaakt > message
	    pqinit
	    echo Het corpus Alpino Treebank wordt ingevoerd > message
	    echo /mod/corpora/cdb.dact | \
		pqbuild -w -p '/mod/corpora/' alpinotreebank 'Alpino Treebank' none 1
	    echo
	fi

	echo PaQu wordt gestart > message
	# cd: anders werk pqbugtest niet
	cd /mod/paqu/bin
	exec pqserve
	;;

    install_lassy)
	if [ "`/mod/tools/corpustest lassysmall`" = "ok" ]
	then
	    echo 'Het corpus `lassysmall` is al aanwezig'
	    exit
	fi

	if [ ! -f /mod/data/corpora/lassy.dact ]
	then
	    echo Bestand niet gevonden: /mod/data/corpora/lassy.dact
	    exit
	fi
	echo /mod/data/corpora/lassy.dact | \
		pqbuild -w -p '/mod/data/corpora/' lassysmall 'Lassy Klein' none 1

	;;

    clean|pqclean)
	pqclean -c
	;;

    rmcorpus|pqrmcorpus)
	shift
	pqrmcorpus "$@"
	;;

    rmuser|pqrmuser)
	shift
	pqrmuser "$@"
	;;

    setquota|pqsetquota)
	shift
	pqsetquota "$@"
	;;

    status|pqstatus)
	pqstatus
	;;

    shell)
	echo
	echo Beschikbare editor: nano
	echo
	/bin/bash --rcfile /mod/etc/init.sh
	;;

    *)
	echo Start deze container met een van de volgende commando\'s:
	echo '    serve          - run de server'
	echo '    install_lassy  - installeer het corpus Lassy Klein'
	echo '    clean          - verwijder oude gebruikers zonder corpora'
	echo '    rmcorpus       - verwijder een corpus'
	echo '    rmuser         - verwijder een gebruiker en al z'\''n corpora'
	echo '    setquota       - zet quotum voor een of meer gebruikers'
	echo '    status         - overzicht van gebruikers en hun corpora'
	echo '    shell          - start interactieve shell'
	;;

esac
