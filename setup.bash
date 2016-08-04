#!/bin/bash

script='
@parts = ("/");
$p = "";
foreach $part (split m!/!, $ENV{dir}) {
    if ($part ne "") {
	$p .= "/" . $part;
	push @parts, $p;
    }
}
foreach $p (@parts) {
    $s = `stat -c %A "$p"`;
    if ($s =~ /d(...){0,2}..-/) {
        print "$p";
	exit;
    }
}
'

echo >> paqu.bash
if [ $? != 0 ]
then
    echo Het script paqu.bash kan niet aangemaakt worden
    echo Draai setup.bash in een directory waar je schrijfrechten hebt
    echo Setup afgebroken
    exit
fi

os=`docker version -f {{.Client.Os}}`

vagrant=no
if [ "$os" = darwin ]
then
    echo
    read -p 'Gebruik je Vagrant? (j/n) ' JN
    case "$JN" in
	[jJyY]*)
	    vagrant=yes
	    ;;
    esac
fi

echo
echo Plaats waar PaQu bestanden opslaat
echo 'LET OP: De hoeveel data kan flink oplopen!'
echo Voorbeeld: $HOME/paqu-data
read -p 'Directory: ' DATA
if [ "$DATA" = "" ]
then
    echo Setup afgebroken
    exit
fi
case "$DATA" in
    /*)
	;;
    *)
	echo Je moet een absoluut path naar een directory opgeven
	echo \'$DATA\' is geen absoluut path
	echo Setup afgebroken
	exit
	;;
esac
if [ -e "$DATA" ]
then
    if [ ! -d "$DATA" ]
    then
	echo \'$DATA\' bestaat en is geen directory
	echo Setup afgebroken
	exit
    fi
    if [ -f "$DATA/setup.toml" ]
    then
	echo Er staat al een setup.toml in \'$DATA\'
	read -p 'Setup vervangen? (j/n) ' JN
	case $JN in
	    [jJyY]*)
	    	;;
	    *)
		echo Setup afgebroken
		exit
		;;
	esac
    else
	shopt -s dotglob
	if [ "`echo $DATA/*`" != "$DATA/"'*' ]
	then
	    echo De directory \'$DATA\' is niet leeg
	    echo Als je echt deze directory wilt gebruiken, doe dan: touch \"$DATA/setup.toml\"
	    echo Setup afgebroken
	    exit
	fi
    fi
else

    echo Directory \'$DATA\' bestaat niet
    read -p 'Directory aanmaken? (j/n) ' JN
    case $JN in
	[jJyY]*)
	    ;;
	*)
	    echo Setup afgebroken
	    exit
	    ;;
    esac

fi
for i in corpora data folia mysql
do
    mkdir -p "$DATA/$i"
    if [ ! -d "$DATA/$i" ]
    then
	echo Maken van directory \'$DATA/$i\' is mislukt
	echo Setup afgebroken
	exit
    fi
done

# ik weet niet of deze test werkt op darwin of windows
if [ "$os" = linux ]
then
    st=`stat -f -c %T "$DATA"`
    case "$st" in
	nfs*)
	    P=`dir="$DATA" perl -e "$script"`
	    if [ "$P" != "" ]
	    then
		echo Het path \'$P\' moet voor iedereen executable zijn
		echo Doe eerst:
		echo "  chmod a+x \"$P\""
		echo Setup afgebroken
		exit
	    fi
	    ;;
    esac
fi

echo
echo Op welke poort wil je PaQu laten draaien?
echo Voorbeeld: 9000
read -p 'Poort: ' PORT
if [ "$PORT" = "" ]
then
    echo Poortnummer ontbreekt
    echo Setup afgebroken
    exit
fi

echo
echo Wat is het adres dat gebruikt moet worden als afzender in mail verstuurd door PaQu?
echo Voorbeeld: maintainer@paqu.nl
read -p 'Adres: ' MAILFROM
if [ "$MAILFROM" = "" ]
then
    echo Adres ontbreekt
    echo Setup afgebroken
    exit
fi

maildomain=`echo $MAILFROM | sed -e 's/.*@//'`

echo
echo Wat is het adres van de smtp-server waarmee PaQu mail kan versturen?
echo TIP: Kijk in je mailprogramma naar de instellingen van smtp.
echo 'Voorbeelden, met/zonder poortnummer (poort 25 is de default):'
echo "  smtp.$maildomain"
echo "  smtp.$maildomain:25"
echo "  smtp.$maildomain:465"
echo "  smtp.$maildomain:587"
read -p 'SMTP-server: ' SMTPSERV
if [ "$SMTPSERV" = "" ]
then
    echo Smtp-server ontbreekt
    echo Setup afgebroken
    exit
fi

echo
echo Is het nodig in te loggen op de smtp-server voordat je er mail heen kunt zenden?
echo Zo ja, geef dan je loginnaam voor de smtp-server
read -p 'Username: ' SMTPUSER
if [ "$SMTPUSER" != "" ]
then
    echo
    echo Geef je password voor de smtp-server
    read -p 'Password: ' SMTPPASS
    if [ "$SMTPPASS" = "" ]
    then
	echo Password ontbreekt
	echo Setup afgebroken
	exit
    fi
fi

export PORT
export MAILFROM
export SMTPSERV
export SMTPUSER
export SMTPPASS

perl -n -e '
$port     = $ENV{PORT};
$mailfrom = $ENV{MAILFROM};
$smtpserv = $ENV{SMTPSERV};
$smtpuser = $ENV{SMTPUSER};
$smtppass = $ENV{SMTPPASS};
$port     =~ s/\\/\\\\/g;
$port     =~ s/\"/\\\"/g;
$mailfrom =~ s/\\/\\\\/g;
$mailfrom =~ s/\"/\\\"/g;
$smtpserv =~ s/\\/\\\\/g;
$smtpserv =~ s/\"/\\\"/g;
$smtpuser =~ s/\\/\\\\/g;
$smtpuser =~ s/\"/\\\"/g;
$smtppass =~ s/\\/\\\\/g;
$smtppass =~ s/\"/\\\"/g;
$smtpserv =~ s/^[^:]+$/$&:25/;

while (<>) {
    s/~CONTACT~/"$contact"/e;
    s/~PORT~/"$port"/e;
    s/~MAILFROM~/"$mailfrom"/eg;
    s/~SMTPSERV~/"$smtpserv"/e;
    s/~SMTPUSER~/"$smtpuser"/e;
    s/~SMTPPASS~/"$smtppass"/e;
    print;
}
' > "$DATA/setup.toml" << 'EOF'
##
## Dit bestand is in toml-formaat, zie: https://github.com/mojombo/toml
##
## Dit is de setup voor deze programma's:
##  - pqbuild
##  - pqclean
##  - pqconfig
##  - pqinit
##  - pqrmcorpus
##  - pqrmuser
##  - pqserve
##  - pqsetquota
##  - pqstatus
##  - pqupgrade

##
## Dit bestand word ingelezen als: $PAQU/setup.toml
##
## Logs worden opgeslagen als: $PAQU/pqserve.log (automatisch geroteerd)
## Overige data wordt opgeslagen in de directory: $PAQU/data
##
## De default voor $PAQU is: $HOME/.paqu
##

## Contact-informatie die verschijnt op de helppagina van PaQu.
contact = "Bij vragen, mail naar <a href=\"mailto:~MAILFROM~\">~MAILFROM~</a>"

# De url waarop de server voor de buitenwereld beschikbaar is, zonodig met poortnummer.
url = "http://localhost:~PORT~/"

# Gegevens die gebruikt worden om mail naar gebruikers te sturen.
# De waarde van 'smtpserv' is verplicht met een poortnummer.
# Als 'smtpuser' en 'smtppass' leeg zijn is het een mailserver waarop
# niet ingelogd hoeft te worden (door degene die `pqserve` draait).
mailfrom = "~MAILFROM~"
smtpserv = "~SMTPSERV~"
smtpuser = "~SMTPUSER~"
smtppass = "~SMTPPASS~"

# Maximum aantal corpora dat gelijktijdig wordt verwerkt.
# De verwerking van een corpus gebruikt ongeveer één processor voor 100%.
maxjob = 2

# Hoeveel data mag een gebruiker uploaden? In aantal tokens, geteld na
# splitsing van de data in tokens, opgeteld bij data die de gebruiker al
# heeft staan.
# Als de waarde 0 is geldt er geen limiet.
# Deze waarde wordt toegekend aan een gebruiker als ie voor het eerst
# inlogt. Verandering van deze waarde in de setup heeft dus alleen
# effect voor nieuwe gebruikers.
# Deze waarde kan achteraf per gebruiker worden aangepast met het
# programma `setquota`.
maxwrd = 1000000

# Maximum aantal zinnen bij het maken van een nieuw corpus op basis van bestaande corpora.
# Als de waarde 0 is geldt er geen limiet.
maxdup = 10000

# Timeout voor Alpino voor de bewerking van één regel. In seconden.
# Het effect is niet exact als er een Alpino-server wordt gebruikt.
timeout = 900

# Maximum aantal tokens per regel. Kies 0 voor geen maximum.
# Wanneer een Alpino-server gebruikt wordt kan die een lagere limiet opleggen.
maxtokens = 100

# URL van een Alpino-server.
# Als dit leeg is wordt de lokale versie van Alpino gebruikt.
# De server moet deze API implementeren: https://github.com/rug-compling/alpino-api
# Een server kan in principe de data parallel verwerken, en dus veel
# sneller zijn dan wanneer je Alpino lokaal gebruikt.
alpinoserver = ""

# Een willekeurige tekst die wordt gebruikt voor versleuteling bij het
# inloggen.
# VERANDER DIT IN EEN ANDERE TEKST.
# Als je opnieuw de tekst verandert moet iedere gebruiker opnieuw
# inloggen.
secret = "Er gaat niets boven Groningen!"

# TODO: uitleg over https met/zonder poortnummer

# Https gebruiken? In dat geval moet je zorgen voor de bestanden
# `cert.pem` en `key.pem` in de directory die aangegeven wordt door
# $PAQU. Laat het certificaat ondertekenen door een Certificaatautoriteit,
# zie: http://nl.wikipedia.org/wiki/Certificaatautoriteit
https = false

# Accepteer zowel https als http? Http wordt dan omgezet in een
# redirect naar https. Dit is enigszins experimenteel. Als dit
# problemen veroorzaakt, gebruik dan alleen de optie https.
httpdual = false

# Als `pqserve` via een proxy-server verbonden is met de buitenwereld
# heeft de optie `remote` geen effect, want het remote ip-adres is dan
# altijd dat van de proxy-server. In dat geval kun je de volgende optie
# op 'true' zetten, en dan wordt de waarde van de header X-Forwarded-For
# gebruikt.
forwarded = false

# Hoe lang mag een query via de website bezig zijn voordat een timeout
# wordt gegeven.
# In seconden.
# Als de waarde 0 is wordt er geen timeout gebruikt.
# Als een gebruiker de pagina voor de query verlaat dan wordt de query
# ook onderbroken.
querytimeout = 120

# Gebruik extern programma om in te loggen.
# Dit is de url van een externe website.
# Als dit is gedefinieerd vervangt het de ingebouwde manier van inloggen.
# Zie voorbeeld: extra/pqlogin.go
loginurl = ""

# Na hoeveel dagen moeten FoLiA-bestanden van gebruikers worden verwijderd?
foliadays = 30

# Wie mag de site bekijken?
# Selectie op basis van ip-adres.
# Als dit ontbreekt heeft iedereen toegang.
# Een adres is een ip-adres, een CIDR ip-adresmasker, of het woord "all".
# Voor CIDR, zie: http://nl.wikipedia.org/wiki/Classless_Inter-Domain_Routing .
# De EERSTE regel die matcht bepaalt of de bezoeker toegang heeft.
# Als geen enkele regel matcht heeft de gebruiker toegang.
# Als `pqserve` via een proxy-server met de buitenwereld is verbonden
# kun je dit niet gebruiken. In dat geval moet je de toegang in de
# proxy-server regelen.

#[[view]]
#allow = true
#addr  = [ "127.0.0.1/8", "::1", "123.123.123.123" ]

#[[view]]
#allow = false
#addr  = [ "all" ]

# Wie mag een account aanmaken, en dus zelf corpora uploaden?
# Selectie op basis van e-mailadres.
# Als dit ontbreekt mag iedereen een account aanmaken.
# Een mailadres is een reguliere expressie, zonder hoofdletters, of het woord "all".
# De EERSTE regel die matcht bepaalt of de bezoeker toegang heeft.
# Als geen enkele regel matcht heeft de gebruiker toegang.

#[[access]]
#allow = true
#mail  = [ "@xs4all\\.nl$", "@rug\\.nl$" ]

#[[access]]
#allow = false
#mail  = [ "all" ]

#
# LAAT ONDERSTAANDE WAARDES ONVERANDERD
#

port = 9000
default = "lassysmall alpinotreebank"
login = "$LOGIN"
prefix = "pq"
dact = true
sh = "/bin/sh"
path = "/mod/paqu/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
alpino = "/mod/Alpino"
remote = false

EOF

echo '#!/bin/bash' > paqu.bash
echo >> paqu.bash
echo dir=\"$DATA\" >> paqu.bash
echo port=$PORT >> paqu.bash
echo 'mport=$(($port + 100))' >> paqu.bash
if [ "$os" = linux ]
then
    echo localhost=127.0.0.1 >> paqu.bash
else
    echo 'a=`docker-machine active 2> /dev/null`' >> paqu.bash
    echo 'localhost=`docker-machine ip $a 2> /dev/null || echo 127.0.0.1`' >> paqu.bash
    echo 'unset a' >> paqu.bash
fi
if [ "$os" = linux ]
then
    echo uid=`stat -c %u "$DATA/setup.toml"` >> paqu.bash
    echo gid=`stat -c %g "$DATA/setup.toml"` >> paqu.bash
fi

cat >> paqu.bash  <<'EOF'

if [ ! -e "$dir/setup.toml" ]
then
    echo Bestand bestaat niet: $dir/setup.toml
    exit 1
fi

if [ -d "$dir/setup.toml" ]
then
    echo Is een directory: $dir/setup.toml
    exit 1
fi

if [ ! -r "$dir/setup.toml" ]
then
    echo Kan bestand niet lezen: $dir/setup.toml
    exit 1
fi

case "$1" in
    start)
	docker rm paqu.serve &> /dev/null

	docker rm mysql.paqu &> /dev/null
	echo MySQL wordt gestart
EOF
if [ "$os" = darwin ]
then
    cat >> paqu.bash  <<'EOF'
	docker run \
	    -d \
	    --name=mysql.paqu \
	    -v "$dir"/mysql:/var/lib/mysql \
	    -e MYSQL_ROOT_PASS=root \
	    -e MYSQL_USER_DB=paqu \
	    -e MYSQL_USER_NAME=paqu \
	    -e MYSQL_USER_PASS=paqu \
EOF
    if [ $vagrant = yes ]
    then
	cat >> paqu.bash  <<'EOF'
	    -e VAGRANT_OSX_MODE=true \
	    -e DOCKER_USER_ID=$(id -u) \
	    -e DOCKER_USER_GID=$(id -g) \
EOF
    fi
    cat >> paqu.bash  <<'EOF'
	    dgraziotin/mysql || exit
EOF
else
    cat >> paqu.bash  <<'EOF'
	docker run \
	    -d \
	    --name=mysql.paqu \
	    -v "$dir"/mysql:/var/lib/mysql \
	    -e MYSQL_ROOT_PASSWORD=root \
	    -e MYSQL_DATABASE=paqu \
	    -e MYSQL_USER=paqu \
	    -e MYSQL_PASSWORD=paqu \
EOF
    if [ "$os" = linux ]
    then
	cat >> paqu.bash  <<'EOF'
	    --user=$uid:$gid \
EOF
    fi
    cat >> paqu.bash  <<'EOF'
	    mysql:5.5 || exit
EOF
fi
cat >> paqu.bash  <<'EOF'
	echo MySQL is gestart

	echo PaQu wordt gestart
	rm -f "$dir/ok" "$dir/fail" "$dir/message" "$dir/message.err"
	touch "$dir/message"
	docker run \
	    -d \
	    --link mysql.paqu:mysql \
	    --name=paqu.serve \
	    -p $port:9000 \
	    -v "$dir":/mod/data \
EOF
if [ "$os" = linux ]
then
    cat >> paqu.bash  <<'EOF'
	    --user=$uid:$gid \
EOF
fi
cat >> paqu.bash  <<'EOF'
	    rugcompling/paqu:latest serve || exit
	while [ ! -f "$dir/ok" -a ! -f "$dir/fail" ]
	do
	    cat "$dir/message"
	    sleep 1
	done
	if [ -f "$dir/fail" ]
	then
	    cat "$dir/message.err"
	    echo FOUT
	else
	    echo
	    echo PaQu is gestart op http://$localhost:$port/
	    echo
	fi
	rm -f "$dir/ok" "$dir/fail" "$dir/message" "$dir/message.err"
	;;
    stop)
	docker stop paqu.serve
	docker rm paqu.serve
	docker stop mysql.paqu
	docker rm mysql.paqu
	;;
    install-lassy)
	if [ ! -f "$dir/corpora/lassy.dact" ]
	then
	    echo
	    echo Corpusbestand niet gevonden.
	    echo
	    echo Je kunt het corpus Lassy Klein verkrijgen bij de TST-Centrale:
	    echo http://tst-centrale.org/nl/tst-materialen/corpora/lassy-klein-corpus-detail
	    echo
	    echo Plaats het bestand lassy.dact in de directory \'$dir/corpora/\'
	    echo en draai dit commando opnieuw.
	    echo
	    echo LET OP: Laat het bestand lassy.dact na het installeren staan.
	    echo PaQu blijft dit bestand gebruiken.
	    echo
	    exit
	fi
	docker run \
	    --link mysql.paqu:mysql \
	    --rm \
	    -v "$dir":/mod/data \
EOF
if [ "$os" = linux ]
then
    cat >> paqu.bash  <<'EOF'
	    --user=$uid:$gid \
EOF
fi
cat >> paqu.bash  <<'EOF'
	    rugcompling/paqu:latest install_lassy
	;;
    clean|pqclean|rmcorpus|pqrmcorpus|rmuser|pqrmuser|setquota|pqsetquota|status|pqstatus)
	docker run \
	    --link mysql.paqu:mysql \
	    --rm \
	    -v "$dir":/mod/data \
EOF
if [ "$os" = linux ]
then
    cat >> paqu.bash  <<'EOF'
	    --user=$uid:$gid \
EOF
fi
cat >> paqu.bash  <<'EOF'
	    rugcompling/paqu:latest "$@"
	;;
    up)
	curl http://$localhost:$port/up
	;;
    vars)
	curl http://$localhost:$port/debug/vars
	;;
    env)
	curl http://$localhost:$port/debug/env
	;;
    upgrade-all)
	echo PaQu wordt gestopt
	docker stop paqu.serve
	docker rm paqu.serve
	docker stop mysql.paqu
	docker rm mysql.paqu
EOF
if [ "$os" = darwin ]
then
    cat >> paqu.bash  <<'EOF'
	docker pull dgraziotin/mysql
EOF
else
    cat >> paqu.bash  <<'EOF'
	docker pull mysql:5.5
EOF
fi
cat >> paqu.bash  <<'EOF'
	docker pull phpmyadmin/phpmyadmin
	docker pull rugcompling/paqu:latest
	echo PaQu moet opnieuw gestart worden
	;;
    upgrade)
	echo PaQu wordt gestopt
	docker stop paqu.serve
	docker rm paqu.serve
	docker stop mysql.paqu
	docker rm mysql.paqu
	docker pull rugcompling/paqu:latest
	echo PaQu moet opnieuw gestart worden
	;;
    shell)
	docker run \
	    --rm \
	    -i -t \
	    -v "$dir":/mod/data \
	    rugcompling/paqu:latest shell
	;;
    admin)
	echo
	echo phpMyAdmin wordt gestart op: http://$localhost:$mport/
	echo gebruikersnaam: paqu
	echo wachtwoord: paqu
	echo
	docker run \
	    --link mysql.paqu:db \
	    --rm \
	    -i -t \
	    -p $mport:80 \
	    phpmyadmin/phpmyadmin
	;;
    *)
	echo
	echo Gebruik: paqu.bash CMD [args]
	echo
	echo CMD is een van:
	echo
	echo "  start          - start PaQu"
	echo "  stop           - stop PaQu"
	echo
	echo "  install-lassy  - installeer het corpus Lassy Klein als globaal corpus"
	echo
	echo "  clean          - verwijder oude gebruikers zonder corpora"
	echo "  rmcorpus corp  - verwijder corpus 'corp'"
	echo "  rmuser user    - verwijder gebruiker 'user' en al z'n corpora"
	echo "  setquota quotum user..."
	echo "                 - set quotum voor een of meer gebruikers"
	echo "  status         - geef overzicht van gebruikers en hun corpora"
	echo
	echo "  upgrade        - upgrade naar laatste versie van PaQu"
	echo "  upgrade-all    - upgrade naar laatste versie van PaQu, MySQL, phpMyAdmin"
	echo "  shell          - open een interactieve shell"
	echo "  admin          - start phpMyAdmin"
	echo
	echo "  up             - test of PaQu gereed is"
	echo "  env            - environment voor commando's gestart door PaQu"
	echo "  vars           - interne status van PaQu"
	echo
	echo Voor meer informatie, kijk op:
	echo
	echo "  https://github.com/rug-compling/paqu-docker"
	echo
	;;
esac
EOF

chmod +x paqu.bash

cat <<EOF


================================================================


PaQu is klaar voor gebruik.

EOF
echo Eventueel kun je nog dingen aanpassen in: $DATA/setup.toml
cat <<EOF



Om PaQu te starten, run:

    ./paqu.bash start

De eerste keer duurt dat een paar minuten



Voor een overzicht van andere commando's, run:

    ./paqu.bash


Voor meer informatie, kijk op:

    https://github.com/rug-compling/paqu-docker


EOF
