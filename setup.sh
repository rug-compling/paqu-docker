#!/bin/bash

echo
echo Plaats waar PaQu bestanden opslaat
echo Voorbeeld: /var/paqu/data
read -p "Directory: " DATA
if [ "$DATA" = "" ]
then
    echo Setup afgebroken
    exit
fi
if [ -e "$DATA" ]
then
    if [ ! -d "$DATA" ]
    then
	echo $DATA bestaat en is geen directory
	echo Setup afgebroken
	exit
    fi
    if [ -f "$DATA/setup.toml" ]
    then
	echo Er staat al en setup.toml in $DATA
	read -p "Setup vervangen? (j/n) " JN
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
	    echo De directory $DATA is niet leeg
	    echo Setup afgebroken
	    exit	
	fi
    fi
else

    echo Directory $DATA bestaat niet
    read -p "Directory aanmaken? (j/n) " JN
    case $JN in
	[jJyY]*)
	    ;;
	*)
	    echo Setup afgebroken
	    exit
	    ;;
    esac

fi
mkdir -p $DATA/data

echo
echo Server waarop MySQL draait.
echo Laat dit leeg als MySQL op de locale machine draait.
echo Voorbeeld: mysql.paqu.nl
read -p "Server: " SERVER

echo
echo Inlognaam voor MySQL.
echo Voorbeeld: paqu
read -p "Inlognaam: " USER
if [ "$USER" = "" ]
then
    echo Inlognaam ontbreekt
    echo Setup afgebroken
    exit
fi

echo
echo Wachtwoord van gebruiker \"$USER\" voor MySQL.
echo Voorbeeld: paqu
read -p "Wachtwoord: " PASS
if [ "$PASS" = "" ]
then
    echo Wachtwoord ontbreekt
    echo Setup afgebroken
    exit
fi

echo
echo Database voor PaQu van gebruiker \"$USER\" voor MySQL.
echo Voorbeeld: paqu
read -p "Database: " DB
if [ "$DB" = "" ]
then
    echo Database ontbreekt
    echo Setup afgebroken
    exit
fi

if [ "$SERVER" = "" -o "$SERVER" = "localhost" -o "$SERVER" = "127.0.0.1" ]
then
    LOGIN="$USER:$PASS@/$DB"
    NET=host
else
    LOGIN="$USER:$PASS@tcp($SERVER)/$DB"
    NET=default
fi

echo
echo Contact-informatie die op de info-pagina van PaQu komt te staan.
echo Dit moet een geldig stuk HTML zijn.
echo 'Voorbeeld: Bij vragen, mail naar <a href="mailto:help@pagu.nl">help@paqu.nl</a>'
read -p "Contact: " CONTACT

echo
echo Op welke poort wil je PaQu laten draaien?
echo Voorbeeld: 9000
read -p "Poort: " PORT
if [ "$PORT" = "" ]
then
    echo Poortnummer ontbreekt
    echo Setup afgebroken
    exit
fi

echo
echo Wat is de url waarop PaQu via het web beschikbaar komt?
echo Voorbeeld: http://pagu.nl:$PORT/
read -p "Url: " URL
if [ "$URL" = "" ]
then
    echo Url ontbreekt
    echo Setup afgebroken
    exit
fi

echo
echo Wat is het adres dat gebruikt moet worden als afzender in mail verstuurd door PaQu?
echo Voorbeeld: maintainer@paqu.nl
read -p "Adres: " MAILFROM
if [ "$MAILFROM" = "" ]
then
    echo Adres ontbreekt
    echo Setup afgebroken
    exit
fi

echo
echo Wat is het adres van de mailserver waarmee PaQu mail kan versturen?
echo Voorbeeld: smtp.paqu.nl
read -p "Mailserver: " SMTPSERV
if [ "$SMTPSERV" = "" ]
then
    echo Mailserver ontbreekt
    echo Setup afgebroken
    exit
fi

echo
echo Is het nodig in te loggen op de mailserver voordat je er mail heen kunt zenden?
echo Zo ja, geef dan je loginnaam voor de mailserver
read -p "Username: " SMTPUSER
if [ "$SMTPUSER" != "" ]
then
    echo
    echo Geef je password voor de mailserver
    read -p "Password: " SMTPPASS
    if [ "$SMTPPASS" = "" ]
    then
	echo Password ontbreekt
	echo Setup afgebroken
	exit
    fi
fi

export CONTACT
export URL
export MAILFROM
export SMTPSERV
export SMTPUSER
export SMTPPASS
export LOGIN

perl -n -e '
$contact  = $ENV{CONTACT};
$url      = $ENV{URL};
$mailfrom = $ENV{MAILFROM};
$smtpserv = $ENV{SMTPSERV};
$smtpuser = $ENV{SMTPUSER};
$smtppass = $ENV{SMTPPASS};
$login    = $ENV{LOGIN};
$contact  =~ s/\\/\\\\/g;
$contact  =~ s/\"/\\\"/g;
$url      =~ s/\\/\\\\/g;
$url      =~ s/\"/\\\"/g;
$mailfrom =~ s/\\/\\\\/g;
$mailfrom =~ s/\"/\\\"/g;
$smtpserv =~ s/\\/\\\\/g;
$smtpserv =~ s/\"/\\\"/g;
$smtpuser =~ s/\\/\\\\/g;
$smtpuser =~ s/\"/\\\"/g;
$smtppass =~ s/\\/\\\\/g;
$smtppass =~ s/\"/\\\"/g;
$login    =~ s/\\/\\\\/g;
$login    =~ s/\"/\\\"/g;
while (<>) {
    s/~CONTACT~/"$contact"/e;
    s/~URL~/"$url"/e;
    s/~MAILFROM~/"$mailfrom"/e;
    s/~SMTPSERV~/"$smtpserv"/e;
    s/~SMTPUSER~/"$smtpuser"/e;
    s/~SMTPPASS~/"$smtppass"/e;
    s/~LOGIN~/"$login"/e;
    print;
}
' > $DATA/setup.toml << 'EOF'
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

# Maximum aantal corpora dat gelijktijdig wordt verwerkt.
# De verwerking van een corpus gebruikt ongeveer één processor voor 100%.
maxjob = 10

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
# Dit heeft geen effect als er een Alpino-server wordt gebruikt.
timeout = 900

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

contact = "~CONTACT~"
url = "~URL~"
port = 9000
default = "alpinotreebank"
mailfrom = "~MAILFROM~"
smtpserv = "~SMTPSERV~:25"
smtpuser = "~SMTPUSER~"
smtppass = "~SMTPPASS~"
login = "~LOGIN~"
prefix = "pq"
dact = true
sh = "/bin/sh"
path = "/mod/paqu/bin:/mod/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
alpino = "/mod/Alpino"
alpino15 = true
remote = false

EOF

echo '#!/bin/bash' > paqu.sh
echo >> paqu.sh
echo dir=$DATA >> paqu.sh
echo port=$PORT >> paqu.sh
echo net=$NET >> paqu.sh

cat >> paqu.sh  <<'EOF'
user=`ls -ln $dir/setup.toml | awk '{ print $3 ":" $4 }'`

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
    serve)
	docker rm paqu.serve &> /dev/null 
	docker run \
	    --name=paqu.serve \
	    --net=$net \
	    -i -t \
	    -p $port:9000 \
	    -v $dir:/mod/data \
	    -u $user \
	    pebbe/paqu:latest serve
	;;
    status|rmcorpus|rmuser)
	docker run \
	    --rm \
	    --net=$net \
	    -v $dir:/mod/data \
	    pebbe/paqu:latest $*
	;;
    shell)
	docker run \
	    --rm \
	    --net=$net \
	    -i -t \
	    -v $dir:/mod/data \
	    pebbe/paqu:latest shell
	;;
    *)
	echo
	echo Gebruik: paqu.sh CMD [args]
	echo
	echo CMD is een van:
	echo
	echo "  serve          - start de PaQu-server"
	echo "  status         - geef overzicht van gebruikers en hun corpora"
	echo "  rmuser user    - verwijder gebruiker 'user' en al z'n corpora"
	echo "  rmcorpus corp  - verwijder corpus 'corp'"
	echo "  shell          - open een interactieve shell"
	echo
	;;
esac
EOF

chmod +x paqu.sh
