#!/bin/bash

export LOGIN="paqu:paqu@tcp($MYSQL_PORT_3306_TCP_ADDR:$MYSQL_PORT_3306_TCP_PORT)/paqu"

function cleanexit {
    if [ "$cpid" != "" ]
    then
        kill $cpid
	sleep 2
    fi
    exit
}

case "$1" in

    serve|pqserve)

	trap cleanexit 1 2 3 9 15

	cd /mod/data

	grep -q '^conllu' setup.toml
	if [ $? != 0 ]
	then
	    echo conllu = true >> setup.toml
	fi

	echo Wachten tot MySQL beschikbaar is > message
	/mod/tools/dbwait &> message.err
	if [ $? != 0 ]
	then
	    touch fail
	    exit
	fi
	rm message.err

	redo=0
	if [ ! -f /mod/data/data/alpinotreebank/cdbdate ]
	then
	    redo=1
	elif [ "$(< /mod/data/data/alpinotreebank/cdbdate)" != "$(< /mod/corpora/cdbdate)" ]
	then
	    redo=1
	elif [ ! -f /mod/data/data/alpinotreebank/cdbversion ]
	then
	    redo=1
	elif [ "$(< /mod/data/data/alpinotreebank/cdbversion)" != "$(< /mod/corpora/cdbversion)" ]
	then
	    redo=1
	fi
	if [ $redo = 1 ]
	then
	    pqrmcorpus alpinotreebank
	fi

	echo De database wordt klaargemaakt > message
	pqinit
	echo De database wordt bijgewerkt naar de huidige versie > message
	pqupgrade
	if [ "`/mod/tools/corpustest alpinotreebank`" != "ok" ]
	then
	    echo Het corpus Alpino Treebank wordt ingevoerd > message
	    echo /mod/corpora/cdb.dact | \
		pqbuild -D $(< /mod/corpora/cdbdate ) -w -p '/mod/corpora/' alpinotreebank 'Alpino Treebank' manual 1
	    mkdir -p /mod/data/data/alpinotreebank
	    cp /mod/corpora/cdb{date,version} /mod/data/data/alpinotreebank
	fi

	pqudupgrade . > pqudupgrade.out 2> pqudupgrade.err &

	echo PaQu wordt gestart > message
	pqserve > pqserve.out 2> pqserve.err &
	cpid=$!
	for i in 1 2 3 4 5 6 7 8
	do
	    sleep 1
	    if [ "`curl -s http://127.0.0.1:9000/up 2> /dev/null`" = "up" ]
	    then
		touch ok
		break
	    fi
	done
	if [ ! -f ok ]
	then
	    echo PaQu reageert niet > message.err
	    touch fail
	    exit
	fi
	wait $cpid
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

	pqdactx /mod/data/corpora/lassy.dact /mod/data/corpora/lassy.dactx.tmp
	mv /mod/data/corpora/lassy.dactx.tmp /mod/data/corpora/lassy.dactx
	echo /mod/data/corpora/lassy.dact | \
		pqbuild -w -p '/mod/data/corpora/' lassysmall 'Lassy Klein' manual 1
	;;

    ud_lassy)
	if [ ! -f /mod/data/corpora/lassy.dact ]
	then
	    echo Bestand niet gevonden: /mod/data/corpora/lassy.dact
	    exit
	fi

	pqudep -o /mod/data/corpora/lassy.dact 2> /mod/data/corpora/lassy.conllu.err
	if [ -f /mod/data/corpora/lassy.dactx ]
	then
	    pqdactx /mod/data/corpora/lassy.dact /mod/data/corpora/lassy.dactx.tmp
	    mv /mod/data/corpora/lassy.dactx.tmp /mod/data/corpora/lassy.dactx
	fi
	pqudep -v > /mod/data/corpora/lassy.conllu.version
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
