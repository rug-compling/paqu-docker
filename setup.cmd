@ECHO OFF

SETLOCAL EnableExtensions EnableDelayedExpansion

ECHO.
ECHO Plaats waar PaQu bestanden opslaat
ECHO LET OP: De hoeveel data kan flink oplopen!
ECHO Voorbeeld: %HOMEDRIVE%%HOMEPATH%\paqu-data
SET DATA=
SET /p "DATA=Directory: "
CALL :Trim DATA %DATA%
IF NOT DEFINED DATA (
    ECHO Setup afgebroken
	GOTO:EOF
)

PUSHD "%DATA%" 2> NUL && POPD && GOTO EndDataNotExists

IF EXIST "%DATA%" (
	ECHO "%DATA%" bestaat en is geen directory
	ECHO Setup afgebroken
	GOTO:EOF
)

ECHO Directory "%DATA%" bestaat niet
SET JN=
SET /p "JN=Directory aanmaken? (j/n) "
CALL :JaNee
IF NOT "%JN%"=="j" (
	ECHO Setup afgebroken
	GOTO:EOF
)

MKDIR "%DATA%"
GOTO EndData
:EndDataNotExists

IF NOT EXIST "%DATA%\setup.toml" GOTO EndSetupExists
ECHO Er staat al een setup.toml in '%DATA%'
SET JN=
SET /p "JN=Setup vervangen? (j/n) "
CALL :JaNee
IF NOT "%JN%"=="j" (
	ECHO Setup afgebroken
	GOTO:EOF
)
GOTO EndData
:EndSetupExists

FOR /f %%a IN ('DIR /b "%DATA%"') DO (
	ECHO De directory '%DATA%' is niet leeg
    ECHO Als je echt deze directory wilt gebruiken, doe dan: ECHO ^> "%DATA%\setup.toml"
	ECHO Setup afgebroken
	GOTO:EOF
)

:EndData
CALL :DataFull "%DATA%"

CALL :MkSub corpora
IF "%ERROR%"=="1" GOTO:EOF
CALL :MkSub data
IF "%ERROR%"=="1" GOTO:EOF
CALL :MkSub folia
IF "%ERROR%"=="1" GOTO:EOF
CALL :MkSub mysql
IF "%ERROR%"=="1" GOTO:EOF

ECHO.
ECHO Op welke poort wil je PaQu laten draaien?
ECHO Voorbeeld: 9000
SET PORT=
SET /p "PORT=Poort: "
CALL :Trim PORT %PORT%
IF NOT DEFINED PORT (
    ECHO Poortnummer ontbreekt
    ECHO Setup afgebroken
    GOTO:EOF
)

ECHO.
ECHO Wat is het adres dat gebruikt moet worden als afzender in mail verstuurd door PaQu?
ECHO Voorbeeld: maintainer@paqu.nl
SET MAILFROM=
SET /p "MAILFROM=Adres: "
CALL :Trim MAILFROM %MAILFROM%
IF NOT DEFINED MAILFROM (
    ECHO Adres ontbreekt
    ECHO Setup afgebroken
    GOTO:EOF
)

FOR /F "tokens=2 delims=@" %%a IN ("%MAILFROM%") DO SET maildomain=%%a
CALL :Trim maildomain %maildomain%
IF NOT DEFINED maildomain SET maildomain=paqu.nl

ECHO.
ECHO Wat is het adres van de smtp-server waarmee PaQu mail kan versturen?
ECHO TIP: Kijk in je mailprogramma naar de instellingen van smtp.
ECHO Voorbeelden, met/zonder poortnummer (poort 25 is de default):
ECHO   smtp.%maildomain%
ECHO   smtp.%maildomain%:25
ECHO   smtp.%maildomain%:465
ECHO   smtp.%maildomain%:587
SET SMTPSERV=
SET /p "SMTPSERV=SMTP-server: "
CALL :Trim SMTPSERV %SMTPSERV%
IF NOT DEFINED SMTPSERV (
    ECHO SMTP-server ontbreekt
    ECHO Setup afgebroken
    GOTO:EOF
)
FOR /F "tokens=1* delims=:" %%a IN ("%SMTPSERV%") DO SET p=%%b
IF NOT DEFINED p SET SMTPSERV=%SMTPSERV%:25

ECHO.
ECHO Is het nodig in te loggen op de SMTP-server voordat je er mail heen kunt zenden?
ECHO Zo ja, geef dan je loginnaam voor de SMTP-server
SET SMTPUSER=
SET /p "SMTPUSER=Username: "
CALL :Trim SMTPUSER %SMTPUSER%

SET SMTPPASS=
IF NOT DEFINED SMTPUSER GOTO EndMailPass
ECHO.
ECHO Geef je password voor de mailserver
SET /p "SMTPPASS=Password: "
CALL :Trim SMTPPASS %SMTPPASS%
IF NOT DEFINED SMTPPASS (
    ECHO Password ontbreekt
    ECHO Setup afgebroken
    GOTO:EOF
)
:EndMailPass

CALL :dirfix "%DATA%"

SET out="%DATA%\setup.toml"

ECHO ##> %out%
ECHO ## Dit bestand is in toml-formaat, zie: https://github.com/mojombo/toml>> %out%
ECHO ##>> %out%
ECHO ## Dit is de setup voor deze programma's:>> %out%
ECHO ##  - pqbuild>> %out%
ECHO ##  - pqclean>> %out%
ECHO ##  - pqconfig>> %out%
ECHO ##  - pqinit>> %out%
ECHO ##  - pqrmcorpus>> %out%
ECHO ##  - pqrmuser>> %out%
ECHO ##  - pqserve>> %out%
ECHO ##  - pqsetquota>> %out%
ECHO ##  - pqstatus>> %out%
ECHO ##  - pqupgrade>> %out%
ECHO.>> %out%
ECHO ##>> %out%
ECHO ## Dit bestand word ingelezen als: $PAQU/setup.toml>> %out%
ECHO ##>> %out%
ECHO ## Logs worden opgeslagen als: $PAQU/pqserve.log (automatisch geroteerd)>> %out%
ECHO ## Overige data wordt opgeslagen in de directory: $PAQU/data>> %out%
ECHO ##>> %out%
ECHO ## De default voor $PAQU is: $HOME/.paqu>> %out%
ECHO ##>> %out%
ECHO.>> %out%
ECHO ## Contact-informatie die verschijnt op de helppagina van PaQu.>> %out%
ECHO contact = "Bij vragen, mail naar <a href=\"mailto:%MAILFROM%\">%MAILFROM%</a>">> %out%
ECHO.>> %out%
ECHO # De url waarop de server voor de buitenwereld beschikbaar is, zonodig met poortnummer.>> %out%
ECHO url = "http://localhost:%PORT%/">> %out%
ECHO.>> %out%
ECHO # Gegevens die gebruikt worden om mail naar gebruikers te sturen.>> %out%
ECHO # De waarde van 'smtpserv' is verplicht met een poortnummer.>> %out%
ECHO # Als 'smtpuser' en 'smtppass' leeg zijn is het een mailserver waarop>> %out%
ECHO # niet ingelogd hoeft te worden (door degene die `pqserve` draait).>> %out%
ECHO mailfrom = "%MAILFROM%">> %out%
ECHO smtpserv = "%SMTPSERV%">> %out%
ECHO smtpuser = "%SMTPUSER%">> %out%
ECHO smtppass = "%SMTPPASS%">> %out%
ECHO.>> %out%
ECHO # Maximum aantal corpora dat gelijktijdig wordt verwerkt.>> %out%
ECHO # De verwerking van een corpus gebruikt ongeveer één processor voor 100%%.>> %out%
ECHO maxjob = 2 >> %out%
ECHO.>> %out%
ECHO # Hoeveel data mag een gebruiker uploaden? In aantal tokens, geteld na>> %out%
ECHO # splitsing van de data in tokens, opgeteld bij data die de gebruiker al>> %out%
ECHO # heeft staan.>> %out%
ECHO # Als de waarde 0 is geldt er geen limiet.>> %out%
ECHO # Deze waarde wordt toegekend aan een gebruiker als ie voor het eerst>> %out%
ECHO # inlogt. Verandering van deze waarde in de setup heeft dus alleen>> %out%
ECHO # effect voor nieuwe gebruikers.>> %out%
ECHO # Deze waarde kan achteraf per gebruiker worden aangepast met het>> %out%
ECHO # programma `setquota`.>> %out%
ECHO maxwrd = 1000000>> %out%
ECHO.>> %out%
ECHO # Maximum aantal zinnen bij het maken van een nieuw corpus op basis van bestaande corpora.>> %out%
ECHO # Als de waarde 0 is geldt er geen limiet.>> %out%
ECHO maxdup = 10000>> %out%
ECHO.>> %out%
ECHO # Geëxpandeerde dact-bestanden gebruiken?>> %out%
ECHO # Als dit aan staat worden sommige XPATH-query's veel eenvoudiger omdat>> %out%
ECHO # lege index-nodes worden aangevuld met data uit de corresponderende>> %out%
ECHO # niet-lege index-nodes.>> %out%
ECHO # Met deze optie neemt de data op schijf ongeveer twee keer zoveel>> %out%
ECHO # ruimte in.>> %out%
ECHO dactx = true>> %out%
ECHO.>> %out%
ECHO # Maximum aantal zinnen in een corpus dat beschikbaar is in het onderdeel SPOD.>> %out%
ECHO # Als de waarde 0 is geldt er geen limiet.>> %out%
ECHO maxspodlines = 1000000>> %out%
ECHO.>> %out%
ECHO # Maximum aantal jobs dat gelijktijdig uitgevoerd kan worden voor het onderdeel SPOD.>> %out%
ECHO maxspodjob = 2>> %out%
ECHO.>> %out%
ECHO # Timeout voor Alpino voor de bewerking van één regel. In seconden.>> %out%
ECHO # Het effect is niet exact als er een Alpino-server wordt gebruikt.>> %out%
ECHO timeout = 900>> %out%
ECHO.>> %out%
ECHO # Maximum aantal tokens per regel. Kies 0 voor geen maximum.>> %out%
ECHO # Wanneer een Alpino-server gebruikt wordt kan die een lagere limiet opleggen.>> %out%
ECHO maxtokens = 100>> %out%
ECHO.>> %out%
ECHO # URL van een Alpino-server.>> %out%
ECHO # Als dit leeg is wordt de lokale versie van Alpino gebruikt.>> %out%
ECHO # De server moet deze API implementeren: https://github.com/rug-compling/alpino-api>> %out%
ECHO # Een server kan in principe de data parallel verwerken, en dus veel>> %out%
ECHO # sneller zijn dan wanneer je Alpino lokaal gebruikt.>> %out%
ECHO alpinoserver = "">> %out%
ECHO.>> %out%
ECHO # Een willekeurige tekst die wordt gebruikt voor versleuteling bij het>> %out%
ECHO # inloggen.>> %out%
ECHO # VERANDER DIT IN EEN ANDERE TEKST.>> %out%
ECHO # Als je opnieuw de tekst verandert moet iedere gebruiker opnieuw>> %out%
ECHO # inloggen.>> %out%
ECHO secret = "Er gaat niets boven Groningen!">> %out%
ECHO.>> %out%
ECHO # TODO: uitleg over https met/zonder poortnummer>> %out%
ECHO.>> %out%
ECHO # Https gebruiken? In dat geval moet je zorgen voor de bestanden>> %out%
ECHO # `cert.pem` en `key.pem` in de directory die aangegeven wordt door>> %out%
ECHO # $PAQU. Laat het certificaat ondertekenen door een Certificaatautoriteit,>> %out%
ECHO # zie: http://nl.wikipedia.org/wiki/Certificaatautoriteit>> %out%
ECHO https = false>> %out%
ECHO.>> %out%
ECHO # Accepteer zowel https als http? Http wordt dan omgezet in een>> %out%
ECHO # redirect naar https. Dit is enigszins experimenteel. Als dit>> %out%
ECHO # problemen veroorzaakt, gebruik dan alleen de optie https.>> %out%
ECHO httpdual = false>> %out%
ECHO.>> %out%
ECHO # Als `pqserve` via een proxy-server verbonden is met de buitenwereld>> %out%
ECHO # heeft de optie `remote` geen effect, want het remote ip-adres is dan>> %out%
ECHO # altijd dat van de proxy-server. In dat geval kun je de volgende optie>> %out%
ECHO # op 'true' zetten, en dan wordt de waarde van de header X-Forwarded-For>> %out%
ECHO # gebruikt.>> %out%
ECHO forwarded = false>> %out%
ECHO.>> %out%
ECHO # Hoe lang mag een query via de website bezig zijn voordat een timeout>> %out%
ECHO # wordt gegeven.>> %out%
ECHO # In seconden.>> %out%
ECHO # Als de waarde 0 is wordt er geen timeout gebruikt.>> %out%
ECHO # Als een gebruiker de pagina voor de query verlaat dan wordt de query>> %out%
ECHO # ook onderbroken.>> %out%
ECHO querytimeout = 120>> %out%
ECHO.>> %out%
ECHO # Gebruik extern programma om in te loggen.>> %out%
ECHO # Dit is de url van een externe website.>> %out%
ECHO # Als dit is gedefinieerd vervangt het de ingebouwde manier van inloggen.>> %out%
ECHO # Zie voorbeeld: extra/pqlogin.go>> %out%
ECHO loginurl = "">> %out%
ECHO.>> %out%
ECHO # Na hoeveel dagen moeten FoLiA-bestanden van gebruikers worden verwijderd?>> %out%
ECHO foliadays = 30>> %out%
ECHO.>> %out%
ECHO # Wie mag de site bekijken?>> %out%
ECHO # Selectie op basis van ip-adres.>> %out%
ECHO # Als dit ontbreekt heeft iedereen toegang.>> %out%
ECHO # Een adres is een ip-adres, een CIDR ip-adresmasker, of het woord "all".>> %out%
ECHO # Voor CIDR, zie: http://nl.wikipedia.org/wiki/Classless_Inter-Domain_Routing .>> %out%
ECHO # De EERSTE regel die matcht bepaalt of de bezoeker toegang heeft.>> %out%
ECHO # Als geen enkele regel matcht heeft de gebruiker toegang.>> %out%
ECHO # Als `pqserve` via een proxy-server met de buitenwereld is verbonden>> %out%
ECHO # kun je dit niet gebruiken. In dat geval moet je de toegang in de>> %out%
ECHO # proxy-server regelen.>> %out%
ECHO.>> %out%
ECHO #[[view]]>> %out%
ECHO #allow = true>> %out%
ECHO #addr  = [ "127.0.0.1/8", "::1", "123.123.123.123" ]>> %out%
ECHO.>> %out%
ECHO #[[view]]>> %out%
ECHO #allow = false>> %out%
ECHO #addr  = [ "all" ]>> %out%
ECHO.>> %out%
ECHO # Wie mag een account aanmaken, en dus zelf corpora uploaden?>> %out%
ECHO # Selectie op basis van e-mailadres.>> %out%
ECHO # Als dit ontbreekt mag iedereen een account aanmaken.>> %out%
ECHO # Een mailadres is een reguliere expressie, zonder hoofdletters, of het woord "all".>> %out%
ECHO # De EERSTE regel die matcht bepaalt of de bezoeker toegang heeft.>> %out%
ECHO # Als geen enkele regel matcht heeft de gebruiker toegang.>> %out%
ECHO.>> %out%
ECHO #[[access]]>> %out%
ECHO #allow = true>> %out%
ECHO #mail  = [ "@xs4all\\.nl$", "@rug\\.nl$" ]>> %out%
ECHO.>> %out%
ECHO #[[access]]>> %out%
ECHO #allow = false>> %out%
ECHO #mail  = [ "all" ]>> %out%
ECHO.>> %out%
ECHO #>> %out%
ECHO # LAAT ONDERSTAANDE WAARDES ONVERANDERD>> %out%
ECHO #>> %out%
ECHO.>> %out%
ECHO port = 9000>> %out%
ECHO default = "lassysmall alpinotreebank">> %out%
ECHO login = "$LOGIN">> %out%
ECHO prefix = "pq">> %out%
ECHO dact = true>> %out%
ECHO sh = "/bin/sh">> %out%
ECHO path = "/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin">> %out%
ECHO alpino = "/mod/Alpino">> %out%
ECHO remote = false>> %out%
ECHO conllu = true>> %out%
ECHO.>> %out%


ECHO @ECHO OFF> paqu.cmd
ECHO SETLOCAL EnableExtensions EnableDelayedExpansion>> paqu.cmd
ECHO SET dir=%DATA%>> paqu.cmd
ECHO SET udir=%udir%>> paqu.cmd
ECHO SET port=%PORT%>> paqu.cmd
ECHO SET /a mport=%%port%% + 100>> paqu.cmd
ECHO SET localhost=127.0.0.1>> paqu.cmd
ECHO SET machine=default>> paqu.cmd
ECHO FOR /f %%%%a in ('docker-machine active') DO SET machine=%%%%a>> paqu.cmd
ECHO FOR /f %%%%a in ('docker-machine ip %%machine%%') DO SET localhost=%%%%a>> paqu.cmd
ECHO IF NOT EXIST "%%dir%%\setup.toml" (>> paqu.cmd
ECHO     ECHO Bestand bestaat niet: %%dir%%\setup.toml>> paqu.cmd
ECHO     GOTO:EOF>> paqu.cmd
ECHO )>> paqu.cmd
ECHO. >> paqu.cmd
ECHO SET CMD=%%1>> paqu.cmd
ECHO SET ALL=%%*>> paqu.cmd
ECHO. >> paqu.cmd
ECHO IF NOT "%%CMD%%"=="start" GOTO EndStart>> paqu.cmd
ECHO.>> paqu.cmd
ECHO docker rm paqu.serve 2^> NUL>> paqu.cmd
ECHO.>> paqu.cmd
ECHO docker rm mysql.paqu 2^> NUL>> paqu.cmd
ECHO ECHO MySQL wordt gestart>> paqu.cmd
ECHO docker run -d --name=mysql.paqu -v "%%udir%%/mysql:/var/lib/mysql" -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=paqu -e MYSQL_USER=paqu -e MYSQL_PASSWORD=paqu mysql:5.5>> paqu.cmd
ECHO IF NOT "%%ERRORLEVEL%%"=="0" GOTO:EOF>> paqu.cmd
ECHO ECHO MySQL is gestart>> paqu.cmd
ECHO.>> paqu.cmd
ECHO ECHO PaQu wordt gestart>> paqu.cmd
ECHO DEL "%%dir%%\ok" 2^> NUL>> paqu.cmd
ECHO DEL "%%dir%%\fail" 2^> NUL>> paqu.cmd
ECHO DEL "%%dir%%\message" 2^> NUL>> paqu.cmd
ECHO DEL "%%dir%%\message.err" 2^> NUL>> paqu.cmd
ECHO ECHO. ^> "%%dir%%/message">> paqu.cmd
ECHO docker run -d --link mysql.paqu:mysql --name=paqu.serve -p %%port%%:9000 -v "%%udir%%:/mod/data" registry.webhosting.rug.nl/compling/paqu:latest serve>> paqu.cmd
ECHO IF NOT "%%ERRORLEVEL%%"=="0" GOTO:EOF>> paqu.cmd
ECHO :Loop>> paqu.cmd
ECHO IF EXIST "%%dir%%\ok" GOTO EndLoop>> paqu.cmd
ECHO IF EXIST "%%dir%%\fail" GOTO EndLoop>> paqu.cmd
ECHO TYPE "%%dir%%\message">> paqu.cmd
ECHO ping -n 2 -w 1000 127.0.0.1 ^> NUL>> paqu.cmd
ECHO GOTO Loop>> paqu.cmd
ECHO :EndLoop>> paqu.cmd
ECHO IF EXIST "%%dir%%\fail" (>> paqu.cmd
ECHO     TYPE "%%dir%%\message.err">> paqu.cmd
ECHO     ECHO FOUT>> paqu.cmd
ECHO )>> paqu.cmd
ECHO IF EXIST "%%dir%%\ok" (>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     ECHO PaQu is gestart op http://%%localhost%%:%%port%%/>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO )>> paqu.cmd
ECHO DEL "%%dir%%\ok" 2^> NUL>> paqu.cmd
ECHO DEL "%%dir%%\fail" 2^> NUL>> paqu.cmd
ECHO DEL "%%dir%%\message" 2^> NUL>> paqu.cmd
ECHO DEL "%%dir%%\message.err" 2^> NUL>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndStart>> paqu.cmd
ECHO.>> paqu.cmd
ECHO IF NOT "%%CMD%%"=="stop" GOTO EndStop>> paqu.cmd
ECHO docker stop paqu.serve>> paqu.cmd
ECHO docker rm paqu.serve>> paqu.cmd
ECHO docker stop mysql.paqu>> paqu.cmd
ECHO docker rm mysql.paqu>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndStop>> paqu.cmd
ECHO.>> paqu.cmd
ECHO IF NOT "%%CMD%%"=="install-lassy" GOTO EndInstallLassy>> paqu.cmd
ECHO IF NOT EXIST "%%dir%%\corpora\lassy.dact" (>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     ECHO Corpusbestand niet gevonden.>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     ECHO Je kunt het corpus Lassy Klein verkrijgen bij het INT:>> paqu.cmd
ECHO     ECHO https://taalmaterialen.ivdnt.org/download/tstc-lassy-klein-corpus/>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     ECHO Plaats het bestand lassy.dact in de directory '%%dir%%\corpora'>> paqu.cmd
ECHO     ECHO en draai dit commando opnieuw.>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     ECHO LET OP: Laat het bestand lassy.dact na het installeren staan.>> paqu.cmd
ECHO     ECHO PaQu blijft dit bestand gebruiken.>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     GOTO:EOF>> paqu.cmd
ECHO )>> paqu.cmd
ECHO docker run --link mysql.paqu:mysql --rm -v "%%udir%%:/mod/data" registry.webhosting.rug.nl/compling/paqu:latest install_lassy>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndInstallLassy>> paqu.cmd
ECHO.>> paqu.cmd
ECHO IF NOT "%%CMD%%"=="ud-lassy" GOTO EndUdLassy>> paqu.cmd
ECHO IF NOT EXIST "%%dir%%\corpora\lassy.dact" (>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     ECHO Corpusbestand niet gevonden.>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     ECHO Je kunt het corpus Lassy Klein verkrijgen bij het INT:>> paqu.cmd
ECHO     ECHO https://taalmaterialen.ivdnt.org/download/tstc-lassy-klein-corpus/>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     ECHO Plaats het bestand lassy.dact in de directory '%%dir%%\corpora'>> paqu.cmd
ECHO     ECHO en draai dit commando opnieuw.>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     ECHO LET OP: Laat het bestand lassy.dact na het installeren staan.>> paqu.cmd
ECHO     ECHO PaQu blijft dit bestand gebruiken.>> paqu.cmd
ECHO     ECHO.>> paqu.cmd
ECHO     GOTO:EOF>> paqu.cmd
ECHO )>> paqu.cmd
ECHO docker run --rm -v "%%udir%%:/mod/data" registry.webhosting.rug.nl/compling/paqu:latest ud_lassy>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndUdLassy>> paqu.cmd
ECHO.>> paqu.cmd
ECHO SET c=no>> paqu.cmd
ECHO FOR %%%%a in ("clean" "pqclean" "rmcorpus" "pqrmcorpus" "rmuser" "pqrmuser" "setquota" "pqsetquota" "status" "pqstatus") DO IF "%%CMD%%"==%%%%a SET c=yes>> paqu.cmd
ECHO IF "%%c%%"=="no" GOTO EndMultiA>> paqu.cmd
ECHO docker run --link mysql.paqu:mysql --rm -v "%%udir%%:/mod/data" registry.webhosting.rug.nl/compling/paqu:latest %%ALL%%>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndMultiA>> paqu.cmd
ECHO.>> paqu.cmd
ECHO SET c=no>> paqu.cmd
ECHO FOR %%%%a in ("vars" "env") DO IF "%%CMD%%"==%%%%a SET c=yes>> paqu.cmd
ECHO IF "%%c%%"=="no" GOTO EndMultiB>> paqu.cmd
ECHO curl http://%%localhost%%:%%port%%/debug/%%CMD%%>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndMultiB>> paqu.cmd
ECHO.>> paqu.cmd
ECHO IF NOT "%%CMD%%"=="up" GOTO EndUp>> paqu.cmd
ECHO curl http://%%localhost%%:%%port%%/up>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndUp>> paqu.cmd
ECHO.>> paqu.cmd
ECHO IF NOT "%%CMD%%"=="upgrade-all" GOTO EndUpgradeAll>> paqu.cmd
ECHO ECHO PaQu wordt gestopt>> paqu.cmd
ECHO docker stop paqu.serve>> paqu.cmd
ECHO docker rm paqu.serve>> paqu.cmd
ECHO docker stop mysql.paqu>> paqu.cmd
ECHO docker rm mysql.paqu>> paqu.cmd
ECHO docker pull mysql:5.5>> paqu.cmd
ECHO docker pull phpmyadmin/phpmyadmin>> paqu.cmd
ECHO docker pull registry.webhosting.rug.nl/compling/paqu:latest>> paqu.cmd
ECHO ECHO PaQu moet opnieuw gestart worden>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndUpgradeAll>> paqu.cmd
ECHO.>> paqu.cmd
ECHO IF NOT "%%CMD%%"=="upgrade" GOTO EndUpgradeOne>> paqu.cmd
ECHO ECHO PaQu wordt gestopt>> paqu.cmd
ECHO docker stop paqu.serve>> paqu.cmd
ECHO docker rm paqu.serve>> paqu.cmd
ECHO docker stop mysql.paqu>> paqu.cmd
ECHO docker rm mysql.paqu>> paqu.cmd
ECHO docker pull registry.webhosting.rug.nl/compling/paqu:latest>> paqu.cmd
ECHO ECHO PaQu moet opnieuw gestart worden>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndUpgradeOne>> paqu.cmd
ECHO.>> paqu.cmd
ECHO IF NOT "%%CMD%%"=="shell" GOTO EndShell>> paqu.cmd
ECHO docker run --rm -i -t -v "%%udir%%:/mod/data" registry.webhosting.rug.nl/compling/paqu:latest shell>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndShell>> paqu.cmd
ECHO.>> paqu.cmd
ECHO IF NOT "%%CMD%%"=="admin" GOTO EndAdmin>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO phpMyAdmin wordt gestart op: http://%%localhost%%:%%mport%%/>> paqu.cmd
ECHO ECHO gebruikersnaam: paqu>> paqu.cmd
ECHO ECHO wachtwoord: paqu>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO docker run --link mysql.paqu:db --rm -i -t -p %%mport%%:80 phpmyadmin/phpmyadmin>> paqu.cmd
ECHO GOTO:EOF>> paqu.cmd
ECHO :EndAdmin>> paqu.cmd
ECHO.>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO Gebruik: paqu.cmd CMD [args]>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO CMD is een van:>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO   start          - start PaQu>> paqu.cmd
ECHO ECHO   stop           - stop PaQu>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO   ud             - update of voeg universal dependencies toe aan het corpus Lassy Klein>> paqu.cmd
ECHO ECHO   install-lassy  - installeer het corpus Lassy Klein als globaal corpus>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO   clean          - verwijder oude gebruikers zonder corpora>> paqu.cmd
ECHO ECHO   rmcorpus corp  - verwijder corpus 'corp'>> paqu.cmd
ECHO ECHO   rmuser user    - verwijder gebruiker 'user' en al z'n corpora>> paqu.cmd
ECHO ECHO   setquota quotum user...>> paqu.cmd
ECHO ECHO                  - set quotum voor een of meer gebruikers>> paqu.cmd
ECHO ECHO   status         - geef overzicht van gebruikers en hun corpora>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO   upgrade        - upgrade naar laatste versie van PaQu>> paqu.cmd
ECHO ECHO   upgrade-all    - upgrade naar laatste versie van PaQu, MySQL, phpMyAdmin>> paqu.cmd
ECHO ECHO   shell          - open een interactieve shell>> paqu.cmd
ECHO ECHO   admin          - start phpMyAdmin>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO   up             - test of PaQu gereed is>> paqu.cmd
ECHO ECHO   env            - environment voor commando's gestart door PaQu>> paqu.cmd
ECHO ECHO   vars           - interne status van PaQu>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO Voor meer informatie, kijk op:>> paqu.cmd
ECHO ECHO.>> paqu.cmd
ECHO ECHO   https://github.com/rug-compling/paqu-docker>> paqu.cmd
ECHO ECHO.>> paqu.cmd

ECHO.
ECHO.
ECHO ================================================================
ECHO.
ECHO.
ECHO PaQu is klaar voor gebruik.
ECHO.
ECHO Eventueel kun je nog dingen aanpassen in: %DATA%\setup.toml
ECHO.
ECHO.
ECHO Om PaQu te starten, run:
ECHO.
ECHO     paqu.cmd start
ECHO.
ECHO De eerste keer duurt dat een paar minuten
ECHO.
ECHO.
ECHO Voor een overzicht van andere commando's, run:
ECHO.
ECHO     paqu.cmd
ECHO.
ECHO.
ECHO Voor meer informatie, kijk op:
ECHO.
ECHO     https://github.com/rug-compling/paqu-docker
ECHO.

GOTO:EOF


:Trim
SET p=%*
FOR /f "tokens=1*" %%a IN ("!p!") DO SET %1=%%b
GOTO:EOF


:JaNee
CALL :Trim JN %JN%
IF "%JN%"=="J" SET JN=j
IF "%JN%"=="y" SET JN=j
IF "%JN%"=="Y" SET JN=j
IF "%JN%"=="N" SET JN=n
GOTO:EOF


:DataFull
SET DATA=%~f1
GOTO:EOF


:MkSub
SET ERROR=0
PUSHD "%DATA%\%1" 2> NUL && POPD && GOTO:EOF
MKDIR "%DATA%\%1"
IF "%ERRORLEVEL%"=="0" GOTO:EOF
SET ERROR=1
ECHO Maken van directory '%DATA%\%1' is mislukt
ECHO Setup afgebroken
GOTO:EOF


:dirfix
REM verander "C:\My path\My file" -> "/c/My path/My file"
REM resultaat in %udir%
SET t=%*
SET t=%t:"=%
FOR /F "tokens=1* delims=:" %%a IN ("%t%") DO (
	SET udir=/%%a
	SET t=%%b
)
CALL :LoCase udir
SET udir=%udir%%t:\=/%
GOTO:EOF


:LoCase
REM Subroutine to convert a variable VALUE to all lower case.
REM The argument for this subroutine is the variable NAME.
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF
