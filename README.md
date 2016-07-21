# PaQu in Docker #

Hiermee kun je PaQu in Docker draaien.

Download en run het script `setup.bash`

Daarna heb je een script `paqu.bash` waarmee je PaQu kunt starten.

* * * * *

Over PaQu zelf, zie:
https://github.com/rug-compling/paqu

## Problemen? ##

Lees eerst de instructies beneden voor je platform.

Nog steeds problemen? Zorg ervoor dat je de laatste versie van
*PaQu voor Docker* gebruikt:

 1. Download en run de laatste versie van `setup.bash`
 2. Run `paqu.bash upgrade-all`
 3. Run `paqu.bash start`

Nog steeds problemen? Ga naar https://github.com/rug-compling/paqu-docker/issues

## Linux ##

Zou gewoon moeten werken.

## Windows ##

**Docker for Windows**

Ondersteuning voor *Docker for Windows* volgt later.

**Docker Toolbox**

Als je `setup.bash` draait wordt als eerste gevraagd een directory op te
geven waar data opgeslagen moet worden. Je moet hier een directory
opgeven die begint met: `/c/Users`

Als je `paqu.bash start` draait in de shell van Docker, en alles gaat
goed, dan zie je als laatste een melding zoals deze:

```
PaQu is gestart op http://192.168.99.100:9000/
```

(IP-adres en poortnummer kunnen afwijken.)

De getoonde URL is waarop PaQu bereikbaar is in de shell van Docker.
Maar die URL is niet bereikbaar voor je webbrowser, want die draait niet
vanuit de shell van Docker. Je kunt een verbinding maken door eenmalig
dit commando te draaien in een gewone shell van Windows:

```
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=9000 connectaddress=192.168.99.100 connectport=9000
```

(Getest met Windows 10, IP-adres en poortnummer zo nodig aanpassen)

Daarna kun je met je browser PaQu bereiken op deze URL:
http://localhost:9000/


## Mac OS X ##

Ik heb dit niet zelf kunnen testen.

Er waren berichten dat de standaard container voor MySQL niet werkt
onder Mac. Daarom wordt in dit geval een alternatief gebruikt. In wat
voor omgeving dit was is me niet bekend. Geldt het ook voor huidige
versies van *Docker Toolbox* en *Docker for Mac*?

**Docker for Mac**

Als je `setup.bash` draait wordt als eerste gevraagd een directory op te
geven waar data opgeslagen moet worden. Het is mij niet bekend of je
elke directory kunt gebruiken. Mogelijk moet je hier een directory
opgeven die begint met: `/Users`

De scripts `setup.bash` en `paqu.bash` zouden in een gewone shell van Mac
moeten werken. Maar in **Docker for Windows** werkt het linken van een
directory naar de docker container momenteel niet. Geen idee hoe dat
onder Mac is.

**Docker Toolkit**

Als je `setup.bash` draait wordt als eerste gevraagd een directory op te
geven waar data opgeslagen moet worden. Je moet hier een directory
opgeven die begint met: `/Users`

Bestaat hier hetzelfde probleem als onder Windows, dat de URL waarop
PaQu beschikbaar is niet bereikbaar is buiten de shell van Docker? En
zo ja, hoe los je dat dan op?
