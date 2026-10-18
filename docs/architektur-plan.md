# Architektur-Plan: Model und Darstellung trennen

Stand: 2026-10-15

## Grundprinzip

Das **Model** rechnet den IST-Zustand der Welt: Boden, Pflanzen, Tiere, später Häuser und Fabriken.
Die **Darstellungen** (Grafik, Sound, später evtl. weitere) lesen diesen Zustand nur und machen daraus etwas Sicht- oder Hörbares.

- Das Model ist reines Dart: keine Imports aus `flame`, `flutter` oder `lib/game/`.
- Das Model kennt keine Darstellung und wartet nie auf eine.
- Eine Darstellung ändert das Model nie direkt. Eingaben (Joystick, Tastatur) gehen über die Model-API.

## Leitlinie für den Code

**Lesbarkeit vor Eleganz.** Gibt es eine gut lesbare und eine Dart-spezifisch elegante Lösung, gewinnt die lesbare, solange sie nicht spürbar langsamer ist.

- einfache Klassen und benannte Methoden statt Mixins, Extension-Tricks oder verschachtelter Generics
- normale Schleifen und `if` statt langer Ketten aus Kaskaden (`..`), `map`/`where`/`fold` oder Pattern-Matching-Akrobatik
- sprechende Namen, lieber eine Zwischenvariable mehr
- nur dort optimieren, wo eine Messung zeigt, dass es nötig ist (z.B. Vorspulen, Schleifen über alle Kacheln)

## 1. Raum

### Koordinaten
- Alle Koordinaten sind **ganze Zahlen ohne Einheit**, auch beim Spieler. Zwei Typen ([cell.dart](../lib/model/cell.dart), [pos.dart](../lib/model/pos.dart)):
  - `Cell(x, y)`: eine Kachel (Spalte, Zeile). Damit arbeiten Layer, Hasen, Pflanzen, `MovementStrategy`.
  - `Pos(x, y)`: eine Position in Einheiten. Damit arbeiten Spieler und Sound.
  - `pos.cell` liefert die Kachel, `cell.center` die Kachelmitte als `Pos`.
- Nur die Grafik kennt Pixel: [pixels.dart](../lib/game/pixels.dart) mit `cellToPixel` und `posToPixel`.
- Konfiguration (Model):
  ```dart
  grid: (
    gridWidth: 1000,  // Kantenlänge einer Kachel in Einheiten, muss gerade sein
    mapWidth: 150,    // Kartenbreite in Kacheln
    mapHeight: 150,   // Kartenhöhe in Kacheln
  )
  ```
- Abgeleitet, nicht konfiguriert: Weltbreite = `mapWidth × gridWidth`, Welthöhe = `mapHeight × gridWidth`.
- Kachelnummer einer Position: `x ~/ gridWidth`.
- Hintergrund für die Wahl 1000: Eine Kachel entspricht gedanklich ~2 m. 1000 Einheiten sind fein genug, damit auch langsame Bewegung (Gehen) pro Echtzeit-Schritt ohne nennenswerten Rundungsfehler ganzzahlig bleibt.

### Zwei Arten von Objekten
| Art | Verhalten bei `setXY()` | Beispiele |
|---|---|---|
| **frei** | Position wird übernommen | Spieler, Vögel, Autos, Reiter |
| **Raster** | rastet auf die **Kachelmitte** ein: `x - x % gridWidth + gridWidth ~/ 2` | Boden, Pflanzen, Hasen, Häuser |

- Umgesetzt: Raster-Objekte (`AgentModel`) speichern ihre `Cell`; ihre `position` ist immer `cell.center`. Damit ist das Einrasten eingebaut, ohne dass es ein `setXY()` braucht.
- Positionen ändert **nur das Model**: `model.move(objekt, cell)` aktualisiert Objekt und Kachel-Index.
- Raster-Objekte stehen im Kachel-Index (`Layer`, ein Objekt pro Kachel und Layer). Freie Objekte stehen in einer Liste; ihre Kachel wird bei Bedarf aus der Position berechnet.
- Im Model gibt es **keine Glättung**: Hasen springen von Kachel zu Kachel.
- Die **Grafik darf gleiten** lassen (Hasen bewegen sich weich zur neuen Kachel). Das ist reine Darstellung; das Model weiß davon nichts.

### Layer, Höhe und Fortbewegung

Layer-Ordnung, von unten nach oben (pro Kachel und Layer höchstens ein Objekt):

```
 5  ActorModel       Hasen, später Füchse …
 4  PlantModel       Gras, Blumen, Unkraut, Bäume
 3  HeightAreaModel  optional: HeightAreaLow-, -Medium-, -HighModel   ← neu
 2  SeedableModel    Boden
 1  PatchModel       Wasser, flaches Wasser, Strand
```

- **`HeightAreaModel` ist optional:** Es liegt nur auf Bergkacheln, als einer von drei Typen: `HeightAreaLowModel`, `HeightAreaMediumModel`, `HeightAreaHighModel`. Boden ohne `HeightAreaModel` ist flaches Land.
- **Das Model kennt keine Höhe als Zahl oder Stufe**, nur Objekttypen und **Verträglichkeiten**.
- **Untergrund einer Kachel:** `model.groundAt(cell)` liefert den Typ des obersten Untergrunds: zuerst der HeightArea-Layer, sonst der Seedable-Layer (`SoilModel`), sonst der Patch-Layer (`BeachModel`, `FlatWaterModel`, `WaterModel`).
- **Verträglichkeiten stehen als Listen von Typen in der Konfiguration**, z.B.:
  ```dart
  grass:   (growsOn: [SoilModel, HeightAreaLowModel]),
  fir:     (growsOn: [HeightAreaLowModel, HeightAreaMediumModel]),
  hopping: (canEnter: [SoilModel, HeightAreaLowModel]),
  walking: (canEnter: [SoilModel, BeachModel, HeightAreaLowModel]),
  seagull: (canEnter: [WaterModel, FlatWaterModel, BeachModel, SoilModel],
            prefers:  [WaterModel, FlatWaterModel]),
  ```
- Pflanzen-Wachstum und Aussaat prüfen `growsOn`. (Die Tannen-Bilder `fir-01…04` sind schon da und werden noch nicht benutzt.)
- Die Kartenerzeugung leitet die Berge aus der vorhandenen Höhenkarte (`diamondSquare`) ab: Die untersten Prozent werden wie heute Wasser, die obersten Prozent werden Berge der drei Typen. Die Anteile stehen in der Konfiguration. Die Höhenkarte selbst wird danach nicht gespeichert.
- **Fortbewegungsart (`MovementMode`) entscheidet zu 100 %, wohin sich ein Objekt bewegen kann.** Das Objekt selbst prüft kein Gelände.
  - `canEnter(model, cell)`: harte Grenze, prüft den Untergrund gegen die Liste `canEnter`.
  - `preference(model, cell)`: Vorliebe zwischen erlaubten Kacheln, über die Liste `prefers` (z.B. Möwe lieber über Wasser).
  - Arten als einfache Klassen, deren Listen in der Konfiguration stehen, z.B. `Walking`, `Running`, `Swimming`, `Hopping`, `Flying`.
  - Belegung ist getrennt davon Sache des Wesens (ein Hase meidet Kacheln mit anderen Hasen; der Spieler als Beobachter nicht).
- Der Spieler kann vorerst **nicht ins Wasser**: Er beherrscht nur gehen und rennen (rennen per Eingabe, gleicher Untergrund wie gehen). Schwimmen kann später als weitere Fortbewegungsart dazukommen; dann wählt er pro Schritt die erste Art, die die Zielkachel erlaubt. Erlaubt keine Art die Kachel, bleibt er stehen und gleitet an der Kante entlang (x und y getrennt prüfen); das gilt auch am Kartenrand.

### Luft (`AirModel`)

- Ein `AirModel` pro Zelle auf einem eigenen Luft-Layer, wie der Boden: **das Objekt hält die Werte, der Layer nur die Objekte.**
- Mehr-Parameter-Objekt: Feinstaub, Luftfeuchtigkeit, Wärme, Wind. Wind = eine der 8 Himmelsrichtungen (`Direction`-`enum` in [direction.dart](../lib/model/direction.dart), jede Richtung kennt ihren Nachbar-Schritt) plus eine Stärke.
- **Die Ausbreitung ist der Wind.** Im `step()` der Luft fragt eine Zelle ihre 8 Nachbarn: Zeigt der Wind des Nachbarn auf mich (`nachbar.cell + nachbar.windDirection.step == cell`), nehme ich einen Anteil seines Feinstaubs (Windstärke × `windTransfer` der Luftart). Ohne Wind bewegt sich nichts. Jede Zelle bläst zu genau einem Nachbarn, also wird nichts doppelt gezählt; die Gesamtmenge bleibt erhalten, am Kartenrand bleibt Staub liegen. Alle Luftzellen laufen jeden Schritt in neu gemischter Reihenfolge.
- **Der Wind passt sich an.** Nach dem Staubtransport mittelt jede Luftzelle die Windvektoren ihrer Nachbarn (Richtung mit Länge 1 mal Stärke) und schiebt ihren eigenen Wind einen Teil des Weges dorthin (`windAdaptation` der Luftart). Aus dem Ergebnis wird wieder eine der 8 Richtungen (die mit dem größten Skalarprodukt) plus Stärke. Ein gleichmäßiger Wind bleibt stabil; ein starker Nachbar zwischen windstillen zieht nur anteilig.
- **Luftarten:** `AirModel` ist abstrakt und hält nur die Werte. Jede Art rechnet ihr Verhalten in ihrem eigenen `step()`, es gibt keine gemeinsame Rechnung (so kann z.B. die Seeluft Feinstaub später anders behandeln):
  - `AirSeaModel` (über Wasser): halbiert in jedem Schritt erst den eigenen Feinstaub und nimmt dann vom Nachbarn auf; über dem Meer klingt Feinstaub ab,
  - `AirLandModel` (flaches Land): erzeugt keinen Wind, lässt ihn nur durch. Normalerweise bremst sie (`air.land.windDamping`); solange ihr `nopCount` läuft, bremst sie nicht. Ist er 0, startet mit `gustChance` ein neuer Durchlass mit zufälliger Länge 0..`gustMaxSteps`,
  - `AirMountainModel` (über Bergen, bremst den Wind: `air.mountain.windDamping`),
  - `AirCoastModel` (über Strand, Quelle der Brise Richtung Land; passt sich selbst nicht an die Nachbarn an),
  - `AirFoothillModel` (Land am Fuß eines echten Bergs, `medium` oder `high`, Quelle des Aufwinds Richtung Berg; niedrige Hügel erzeugen keinen Wind).
  - Brise und Aufwind ändern sich **glatt**: Für eine zufällige Anzahl Schritte (`breezeRunMin`..`breezeRunMax`) steigt oder fällt die Stärke jeden Schritt um `breezeChange` des Maximums, dann wird neu gewürfelt (rauf/runter, Länge). Kein Springen, kein Zappeln.
  Jede Art in ihrer eigenen Datei `air_….dart` und mit eigenem Konfigurations-Knoten (`air.sea`, `air.land`, `air.mountain`, `air.coast`, `air.foothill`), inklusive eigener Startwerte für Feuchte und Wärme.
- **Der Terraformer legt die Luft an** (als letzten Schritt, wenn die Landschaft fest ist). Er wählt die Art nach dem Untergrund und übergibt Strand- und Bergfuß-Luft ihre Richtung (`landward`, `mountainward`). Die Luft selbst weiß nichts über Boden und Berge.
- Der Zufall der Simulation läuft über `model.random` mit dem Karten-Seed, damit ein Lauf wiederholbar ist.
- **Die Luft kennt ihre Leser nicht.** Wer Luft liest oder verändert, entscheidet selbst: Der Baum zieht in seinem eigenen `step()` Feinstaub an seiner Zelle ab (`absorbsDust`), eine Fabrik wird später addieren. Schnittstelle: `addDust(menge)` mit Vorzeichen, unten bei 0 gekappt.
- Geplant: wer den Wind setzt (z.B. ein Wetter-Service), Wärme und Feuchte wirken auf Wachstum und Brände; abgeleitete Zufriedenheit und der Minimum-Index (siehe GDD) lesen diese Werte.

## 2. Zeit

### Takte
- Jedes Objekt meldet sich bei **genau einem Takt** an und darf ihn wechseln (z.B. Hase schläft / flieht).
- Jeder Takt hat ein **festes Intervall in Simulationszeit** (ganze Zahl, Millisekunden).
- `step()` hat **keinen Zeitparameter**. Für ein Objekt dauert ein Schritt immer sein Taktintervall. Regeln werden **pro Schritt** formuliert, wie heute (`energyPerStep` usw.).
- Geschwindigkeiten freier Objekte sind ganzzahlig in **Einheiten pro Schritt**.
- Ein Objekt rechnet immer **genau einen** Schritt. Schleifen über mehrere Schritte macht nur der Controller, damit Wechselwirkungen stimmen.
- Pro Takt einstellbar: zufällige Teilmenge der Objekte pro Schritt (heute `RandomPercentScheduler`).
- Kontext wie die Tageszeit liest ein Objekt über `model.now` (Simulationszeit).

| Takt | Intervall (vorläufig) | dauerhaft? | Wer |
|---|---|---|---|
| echtzeit | ~33 ms (30/s) | nein | Vögel, Autos, Reiter |
| reaktion | 100 ms | nein | Fluchtreaktionen, Kollisionen |
| tier | 1300 ms | ja | Hasen |
| ökologie | nach Messung (Richtung 60 s) | ja | Pflanzen, Wasser, Boden |
| siedlung | 60 s | ja | Häuser, Fabriken |

Alle Intervalle stehen in der Konfiguration.

### Controller (Hauptuhr)
- Lebt im Model. Die Darstellung ruft nur `model.advance(echteZeitSeitLetztemFrame)` auf.
- Der Controller sammelt die Zeit und löst jeden Takt aus, sobald er fällig ist, notfalls mehrmals.
- Sind mehrere Takte gleichzeitig fällig, gilt eine **feste Reihenfolge** (langsam vor schnell).
- Wechselwirkungen zwischen Takten prüft der schnellere Beteiligte.
- Die Uhr wandert aus `WorldVisualization.update` ([world.dart](../lib/game/world.dart)) ins Model.

## 3. Dauerhafte und flüchtige Objekte

- **Dauerhaft:** Boden, Pflanzen, Hasen, Häuser, Fabriken. Werden gespeichert. Ihre Takte laufen beim Vorspulen mit.
- Die Spielerposition wird ebenfalls gespeichert, gehört aber nicht zum Model (siehe Abschnitt 6).
- **Flüchtig:** Vögel, vorbeifahrende Autos, Reiter. Existieren nur bei laufender App, werden aus dem dauerhaften Zustand erzeugt (viele Bäume → mehr Vögel) und weder gespeichert noch vorgespult.

## 4. Speichern und Vorspulen (Tamagotchi-Prinzip)

- Gespeichert wird der dauerhafte Zustand plus Zeitstempel: beim Wechsel in den Hintergrund und regelmäßig zwischendurch, weil das System die App ohne Vorwarnung beenden kann.
- Hintergrund und Bildschirm aus zählen wie „geschlossen“. Es gibt nur zwei Modi: **läuft** und **vorspulen**.
- **Vorspulen:** Δ = jetzt − gespeicherter Zeitstempel, begrenzt auf `maxCatchUp` (Konfiguration, vorerst **20 Minuten**). Der Controller führt die dauerhaften Takte für diese Simulationszeit aus, **ohne zu warten**: gleiche Schritte, gleiche Regeln, gleiches Ergebnis wie bei offener App. Die restliche Zeit verfällt („die Welt hat geschlafen“).
- `maxCatchUp` und die Takt-Intervalle werden so gewählt, dass das Vorspulen nur wenige Sekunden dauert (siehe Schritt 1 Messung).
- Beim Vorspulen wird **nur das Model** aktualisiert. Alle Darstellungen schlafen.

### Ablauf beim Start oder Zurückkehren
1. Zustand laden (oder im Speicher behalten, wenn die App nur im Hintergrund war)
2. Darstellungen schlafen lassen: von Ereignissen abmelden, Sound ausblenden
3. Vorspulen: nur Model, nur dauerhafte Takte, begrenzt durch `maxCatchUp`
4. Darstellungen machen einen **Komplett-Abgleich** mit dem aktuellen Zustand; flüchtige Objekte werden neu erzeugt
5. Darstellungen melden sich für Ereignisse an, Sound wird eingeblendet
6. Normalbetrieb mit allen Takten

## 5. Schnittstelle Model → Darstellung

- **Ereignisse** (fire-and-forget, synchron, beliebig viele Zuhörer): `added`, `removed`, `moved`, `changed`.
- **Lese-API** (Abfragen pro Frame): Objekt auf Kachel, Nachbarschaft, nächstes Objekt eines Typs, aufsummierte Energie eines Typs im Radius usw. (heute verteilt auf `GameModel` und `MovementStrategy`).
- Jede Darstellung hat zwei Wege: **Komplett-Abgleich** aus dem Zustand und **laufende Ereignisse**.

## 6. Darstellungen, Eingänge, Session

```
        EINGÄNGE                      MODEL                  DARSTELLUNGEN
Tastatur    ── Ereignis ──▶                              ──▶  Grafik
Touch       ── Ereignis ──▶         GameModel            ──▶  Sound
(Watch-Geste)                (rechnet den IST-Zustand)   ──▶  (Vibration, Watch, Sprache)
```

### Spieler als Beobachter ([player.dart](../lib/player.dart))
- Der Spieler steht **außerhalb des Models**. Er bestimmt, wo die Kamera hinschaut und wo der Hörer steht, verändert die Welt aber (noch) nicht.
- Die `GameSession` besitzt ihn; Eingabegeräte setzen seine Richtung, Darstellungen lesen seine Position.
- Er bewegt sich stufenlos pro Frame mit `dt`. Das ist erlaubt, weil er nicht zum Model gehört; im Model gilt weiter: feste Schritte, kein `dt`.
- Beim Vorspulen spielt er keine Rolle.
- Soll er später mit der Welt interagieren (Baum pflanzen, Hasen fliehen vor ihm), geht das über den Ereignis-Kanal ins Model.

### Basisklasse `Representation` ([representation.dart](../lib/representation/representation.dart))
- `wake()`: Komplett-Abgleich (`syncAll()`), dann für Model-Ereignisse anmelden.
- `sleep()`: abmelden; das Model rechnet allein weiter (z.B. beim Vorspulen).
- `update(dt)`: pro Frame, solange wach.
- Model-Ereignisse sind standardmäßig leer; jede Darstellung überschreibt nur, was sie braucht.
- Abgeleitet: `GraphicsRepresentation`, `SoundRepresentation`. Später möglich: Vibration, Apple Watch (eigene watchOS-App, Verbindung nicht echtzeitfähig, also nur für grobe Signale), Sprachausgabe.

### Grafik (`lib/game/`, Flame)
- `GraphicsRepresentation` besitzt das Flame-Spiel und sagt der `WorldVisualization`, was sie zeigen soll. Die Flame-Welt ist reines Zeichnen.
- Die Zuordnung Model-Typ → Grafik-Komponente liegt in einer Factory in der Grafik. `createVisualization()` und das Feld `visualization` verschwinden aus dem Model.
- Die Grafik verwaltet selbst eine Zuordnung Model-Objekt → Komponente.
- Umrechnung: `Pixel = Einheiten × tileSize / gridWidth`.
- Grafik-Konfiguration (getrennt vom Model): `tileSize: 64` (Pixel pro Kachel), `tileSpriteSize: 64`, `tileSnap`.
- Bestehendes Viewport-Culling (nur sichtbare Kacheln) bleibt.

### Sound
- Zweiteilig:
  1. **Soundscape-Berechnung** als reine Funktion: (Model, Hörerposition) → Liste (Quelle, Lautstärke, Panorama, Geschwindigkeit). Ohne Audiogerät testbar.
  2. **Audio-Backend** spielt diese Liste ab.
- Hörradius **pro Geräuschquelle** in Einheiten (z.B. Hase klein, Meer groß) statt pauschal 7 Kacheln.
- Lautstärke- und Panorama-Änderungen mit kurzen Rampen (wenige ms) gegen Klicks. Das ist keine Bewegungsglättung.
- Wird aus `JoystickPlayer` ([player.dart](../lib/game/actors/player.dart)) herausgelöst; rechnet nicht mehr in Pixeln.
- Kopfhörer sind Voraussetzung für Links/Rechts-Ortung.

### Eingänge (`lib/input/`)
- Basisklasse `InputDevice`; abgeleitet `KeyboardInputDevice` (über `HardwareKeyboard`, unabhängig von Flame) und `TouchInputDevice` (Joystick, den die Grafik anzeigt).
- Eingänge sind **nur Spieler-Eingaben**. Sie ändern nie eine Darstellung, nur das Model.
- Sie setzen die Richtung des Spielers direkt (der Spieler ist kein Teil des Models). **Geplant für Aktionen, die die Welt verändern:** ein Ereignis-Kanal ins Model:
  - `model.send(ereignis)`; Interessenten im Model melden sich pro Ereignis-Typ an (`model.subscribe<Typ>(...)`), auch mehrere.
  - Ereignisse werden gesammelt und am Anfang des nächsten Takts verarbeitet, nie mitten in einem Schritt.
  - Sender und Empfänger kennen sich nicht.
- Das Sprite der Spielfigur ist nur noch Darstellung und folgt dem `Player`.
- **Nicht** als Eingang: Wetter, Temperatur und ähnliche Umweltwerte. Die kommen später als **Services**, die das Model aktiv fragt.

### Session ([game_session.dart](../lib/game_session.dart))
- Verbindet Model, Eingänge und Darstellungen und treibt sie mit einer eigenen Frame-Schleife (`Ticker`), unabhängig von Flame.
- Pro Frame: Eingänge abfragen, Spieler bewegen, Model-Takt, wache Darstellungen aktualisieren.
- Führt vorübergehend den 1,3-s-Takt, bis Schritt 4 die Takte ins Model bringt.

## 7. Umbau-Schritte

Nach jedem Schritt muss die App laufen.

Stand: ✅ erledigt, 🔶 teilweise, ⏭️ übersprungen

1. ⏭️ **Messen:** Rechenzeit eines Simulationsschritts bei voller Welt, getrennt nach Hasen und Pflanzen. Ergebnis bestimmt die Takt-Intervalle und zeigt, ob `maxCatchUp` über 20 Minuten hinaus erhöht werden kann.
2. ✅ **Entkoppeln:** Zuhörer-Schnittstelle im Model statt `gameVisualization`; `createVisualization()`/`visualization` in eine Grafik-Factory verschieben; `async`/`await` aus der Simulation entfernen; das `assert` auf die Grafik in [rabbit.dart](../lib/model/actors/rabbit.dart) entfernen. Danach importiert `lib/model/` nichts mehr aus `lib/game/`.
3. ✅ **Koordinaten:** `Pos(int, int)` einführen, `gridWidth`/`mapWidth`/`mapHeight` in die Konfiguration, Raster-Objekte mit Einrasten, `Layer` auf ganzzahlige Kachel-Schlüssel, Grafik rechnet in Pixel um. `Vector2`/Flame aus Model und `MovementStrategy` entfernen.
4. 🔶 **Takte:** Takt-Klasse, Anmeldung pro Objekt, Hauptuhr mit Simulationszeit im Model; den Übergangs-Takt aus `GameSession` ins Model holen; Scheduler werden Optionen pro Takt; Pflanzenwachstum (`_grow`) in den Ökologie-Takt.
   - ✅ Erster Teil umgesetzt ([clock.dart](../lib/model/clock.dart)): Jedes Objekt sagt mit `clock` selbst, auf welchem Takt es läuft (`ecology` als Standard, Hasen `animal`, Luft `air`). Jeder Takt hat ein Intervall in Simulationszeit (ganze ms) und einen Anteil, der pro Schritt zufällig rechnet (`clocks` in der Konfiguration). Das Model führt die Simulationszeit (`now`) und `advance(ms)`; die Takte laufen in fester Reihenfolge Ökologie → Tiere → Luft. Die Session gibt nur noch die Frame-Zeit weiter. Neues Pflanzenwachstum hängt am Ökologie-Takt. Luft läuft jetzt alle 200 ms statt 1300 ms.
   - offen: Echtzeit- und Reaktions-Takt, Takt wechseln zur Laufzeit, Vorspulen über `advance`.
5. 🔶 **Spieler, Darstellungen, Eingänge:**
   - ✅ `Player` als Beobachter außerhalb des Models, Basisklassen `Representation` und `InputDevice`, `GraphicsRepresentation`, `SoundRepresentation`, `KeyboardInputDevice`, `TouchInputDevice`, `GameSession`.
   - offen: Ereignis-Kanal ins Model (nach Schritt 4, weil Ereignisse am Taktanfang verarbeitet werden); Soundscape als reine Funktion; Hörradius pro Quelle; prüfen, ob `flutter_soloud` 3D-Audio mit Doppler zuverlässig unterstützt.
6. **Speichern und Vorspulen:** vollständige Serialisierung des dauerhaften Zustands (heute speichert `toJson` nur `size`), Zeitstempel, `AppLifecycleListener`, Vorspulen mit `maxCatchUp`, Schlafen/Aufwachen der Darstellungen.
7. **Erstes flüchtiges Objekt:** ein Vogel, der an einem stehenden Spieler vorbeifliegt. Beweist freie Bewegung und räumlichen Sound.

8. 🔶 **Untergrund und Fortbewegung:**
   - ✅ `HeightAreaModel` mit drei Typen; Berge an Land aus der Höhenkarte, Felsinseln im Wasser (Gipfel in der Mitte, dann medium, dann low). Anteile und Inselgrößen in der Konfiguration. Kacheln von [tools/terrain_sprite.py](../tools/terrain_sprite.py).
   - ✅ `model.groundTypeAt(cell)`, `MovementMode` (im Model) mit `canEnter`-Liste aus der Konfiguration.
   - ✅ `walking` für den Spieler (Boden, Strand, low, medium); er gleitet an gesperrten Kacheln und am Kartenrand entlang.
   - ✅ `hopping` für die Hasen (Boden, low), auch für die Startplätze. Der Hase prüft selbst nur noch, ob ein anderer Hase auf der Kachel sitzt.
   - ✅ `growsOn` für Pflanzen (Wachstum und Aussaat prüfen den Untergrund). Drei Baumtypen, je ein Höhenband, damit die Grafik stimmt: `TreeModel` (Eiche, `tree-*`) auf Boden, `FirModel` (Tanne, `fir-*`) auf `low`, `PineModel` (Kiefer, `pine-*`, von [tools/pine_sprite.py](../tools/pine_sprite.py)) auf `medium`. Alle drei zählen zum Waldgeräusch. Bergbäume (Tanne, Kiefer) wachsen **licht**: ein Baum mit größeren Nachbarn im Umkreis wächst nicht, verliert Energie und stirbt, so dass auf Fels kein dichter Wald entsteht; die Eiche hat keine solche Grenze. Werte (`crowdingRadius`, `maxCrowdingEnergy`, `crowdingPenalty`) in der Konfiguration.
   - ✅ Landschaftsgestaltung aus dem `GameModel`-Konstruktor in [terraformer.dart](../lib/model/terraformer/terraformer.dart) verschoben; [diamond_square.dart](../lib/model/terraformer/diamond_square.dart) bleibt der reine Höhenkarten-Algorithmus.
   - ✅ Zusammenhängendes Land: [diamond_square.dart](../lib/model/terraformer/diamond_square.dart) mit Seed und ohne den alten Rand-Fehler. Der Terraformer flutet winzige Inseln, baut Landbrücken (3 Kacheln breit) zu größeren Stücken und prüft am Ende mit `walking`, ob jede begehbare Kachel erreichbar ist; sonst wird ein Durchgang gebaut (Gipfel wird medium, Wasser wird Boden). Felsinseln bleiben bewusst unerreichbar. `minIslandSize` in der Konfiguration, Seed in `GameModel`.
   - offen: `prefers`; rennen; Vögel mit `flying`.

Begleitend: Tests für das Model ohne Grafik und Sound (z.B. Hasenpopulation, Einrasten, Takt-Reihenfolge, Vorspulen = gleiches Ergebnis wie Normalbetrieb bei gleichem Zufalls-Seed).

## 8. Offene Punkte

- Verträglichkeits-Listen pro Pflanzentyp und pro Fortbewegungsart; Anteile der drei Bergtypen auf der Karte.
- Spieler: Geschwindigkeiten für gehen und rennen; welche Eingabe rennen auslöst.
- Objekte größer als eine Kachel (Häuser, Fabriken): Der Kachel-Index erlaubt nur ein Objekt pro Kachel und Layer. Lösen, wenn Gebäude kommen.
- Genaue Takt-Intervalle: nach der Messung in Schritt 1. `maxCatchUp` steht vorerst auf 20 Minuten; die Messung zeigt, ob mehr möglich ist.
- Spielergeschwindigkeit: heute 250 px/s ≈ 4 Kacheln/s (Sprint). Für ein Hör-Spiel vermutlich deutlich langsamer.
- Hintergrund-Audio-Modus (Spielen mit dem Handy in der Tasche): bewusst später.
- Vorspulen in einem eigenen Isolate: nur falls es trotz Begrenzung spürbar dauert.
