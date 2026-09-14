# Cuis-Smalltalk-API für den InMoov-Roboter — Benutzerhandbuch

Version: 1.0 (2026-08-24) · Paket: `Inmoov-Mrl` (+ `Inmoov-Demo`, `Tests-Inmoov-Mrl`)
Zielgruppe: Smalltalk-Entwickler, die einen InMoov-Roboter (MyRobotLab, kurz „MRL") aus Cuis-Smalltalk heraus steuern wollen.

---

## 1. Was ist InMoov?

**InMoov** ist ein quelloffener, 3D-gedruckter Lebensgrößen-Humanoid-Roboter des französischen Künstlers **Gael Langevin**. Alle CAD-Dateien (Kopf, Arme, Hände, Torso …) sind frei verfügbar, sodass sich der Roboter weltweit mit einem 3D-Drucker nachbauen lässt. InMoov ist seit 2012 eines der bekanntesten DIY-Robotik-Projekte und wird in Schulen, Museen und Hackerspaces eingesetzt.

**Was kann ein InMoov?**

- **Arme und Hände**: Schulter-, Ellbogen- und Handgelenkbewegungen; Hände mit fünf einzeln ansteuerbaren Fingern.
- **Kopf**: Nicken (`neck`), Drehen (`rothead`), Seitneigung (`rollNeck`), Kiefer (`jaw`), Augen hoch/runter und links/rechts (`eyeX`/`eyeY`) sowie Augenlider (`eyelidLeft`/`eyelidRight`).
- **Torso**: drei Wirbelsäulensegmente (`topStom`, `midStom`, `lowStom`).
- **Gesten**: vordefinierte Bewegungsabläufe als Python-Skripte (z. B. Kopfschütteln „No", Winken), die als Ganzes abgespielt werden.
- **Mehr**: Spracherkennung/-ausgabe, Gesichtserkennung (Tracking), Chatbot-Anbindung — alles Bestandteile von MyRobotLab.

Die Steuerzentrale ist **MyRobotLab (MRL)**, ein Java-basierter Robotik-Server. MRL verwaltet die Servos, bietet eine REST-/Websocket-API und führt die Python-Gesten aus. Unser Cuis-Paket spricht diese REST-API an.

**Weitere Informationen:**

| Quelle | Adresse |
|---|---|
| Projektseite InMoov | <https://inmoov.fr> |
| MyRobotLab | <https://myrobotlab.org> |
| MRL-Quellcode | <https://github.com/myrobotlab/myrobotlab> |
| InMoov-Forum | <https://inmoov.fr/groups/forum> |
| Cuis-Smalltalk | <https://cuis-smalltalk.org> |

---

## 2. Voraussetzungen

1. **MyRobotLab läuft** (lokal oder im Netz), Standardport `8888`.
   Im Projektkontext: Start über `tools/myrobotlab.sh` (virtueller Modus ohne Hardware möglich).
   Der Roboter heißt standardmäßig `i01`.
2. **Cuis-Smalltalk-Image** mit dem Paket **WebClient** (für HTTP).
3. Die Projektpakete `Inmoov-Mrl.pck.st` (API), optional `Inmoov-Demo.pck.st` (Fenster-Oberfläche) und `Tests-Inmoov-Mrl.pck.st` (Unit-Tests).

Prüfen, ob der Roboter erreichbar ist:

```smalltalk
(InmoovRobot host: 'localhost' port: 8888 robotName: 'i01') isAvailable
"→ true"
```

---


## 3. Schnellstart — der Roboter in 15 Zeilen

```smalltalk
| robot |
robot := InmoovRobot host: 'localhost' port: 8888 robotName: 'i01'.

robot isAvailable.                                          "→ true"

"Gruppenbewegung: Arm (alle vier Servos gleichzeitig)"
robot leftArm moveToBicep: 20 rotate: 90 shoulder: 10 omoplate: 90.

"Selektive Bewegung: nil = dieses Servo nicht verändern"
robot leftHand moveToThumb: 170 index: 60 majeure: nil ringFinger: nil pinky: 40.

"Kopf: Nicken, Drehen, Seitneigung — und die Augen separat"
robot head moveToNeck: 100 rotHead: 130 rollNeck: 90.
robot head moveToEyeX: 90 eyeY: 110.

"Torso"
robot torso moveToTopStom: 90 midStom: 80 lowStom: 90.

"(kurz warten, bis die Servos fahren)"
(Delay forMilliseconds: 1500) wait.

(robot leftArm servoNamed: #bicep) position.                "→ z.B. 20.0"

"Wieder alles in die Ruheposition"
robot restAll.
```

Alle Bewegungen sind **asynchron**: `moveTo…` kehrt sofort zurück, während der Roboter noch fährt.

---

## 4. Architektur in einem Blick

```
InmoovRobot                 Fassade: Gruppen, Gesten, restAll, Status
    │ nutzt
InmoovServoGroup            eine Servogruppe (Arm/Hand/Kopf/Torso)
    │ servoNamed: #bicep
InmoovServo                 ein einzelner Servo
    │
InmoovMrlClient             HTTP/REST-Kommunikation mit MyRobotLab
    │
MyRobotLab (localhost:8888)  → i01.leftArm.bicep.moveTo(20.0)
```

Jede Ebene ist einzeln benutzbar: Wer nur einen Finger bewegen will, braucht keinen Roboter; wer rohe REST-Aufrufe machen will, umgeht alle Komfortklassen.

---

## 5. Gruppen- und Servoreferenz

### 5.1 Gruppen am Roboter

| Nachricht am Roboter | Servonamen (Reihenfolge für `moveToArgs:`) |
|---|---|
| `leftArm` / `rightArm` | `bicep`, `rotate`, `shoulder`, `omoplate` |
| `leftHand` / `rightHand` | `thumb`, `index`, `majeure`, `ringFinger`, `pinky`, `wrist` |
| `head` | `neck`, `rothead`, `rollNeck`, `jaw`, `eyeX`, `eyeY`, `eyelidLeft`, `eyelidRight` |
| `torso` | `topStom`, `midStom`, `lowStom` |

Die Namen entsprechen exakt den Service-Namen in MyRobotLab (`i01.head.rothead` usw.).

### 5.2 Bequeme Gruppenbewegungen

```smalltalk
robot leftArm  moveToBicep: 20 rotate: 90 shoulder: 10 omoplate: 90.
robot rightHand moveToThumb: 10 index: 80 majeure: 80 ringFinger: 80 pinky: 80 wrist: 90.
robot leftHand moveToThumb: 0 index: 0 majeure: 0 ringFinger: 0 pinky: 0.   "ohne wrist"
robot head     moveToNeck: 95 rotHead: 70.                    "nur Nicken+Drehen"
robot head     moveToNeck: 95 rotHead: 70 rollNeck: 110.      "+ Seitneigung"
robot head     moveToEyeX: 70 eyeY: 110.                      "Augen"
robot torso    moveToTopStom: 90 midStom: 80 lowStom: 90.
```

### 5.3 Freie Gruppenbewegung mit `nil`

`moveToArgs:` nimmt ein Array in der Reihenfolge aus Tabelle 6.1; `nil` lässt das Servo unberührt:

```smalltalk
robot rightArm moveToArgs: #(nil 120 nil 90).        "nur rotate + omoplate"
```

> **Wichtig:** `nil` funktioniert zuverlässig, weil die API die Pfadform der REST-API nutzt und Dezimalwerte sendet. Ein bekannter MRL-Bug (Integer-Überladung von `moveLeftHand/moveRightHand` crasht bei `null`-Parametern) wird so umgangen.

---

## 6. Der einzelne Servo

```smalltalk
| bicep |
bicep := robot leftArm servoNamed: #bicep.

"Fahren (asynchron)"
bicep moveTo: 45.

"Lesen (synchron)"
bicep position.          "aktuelle Ist-Position"
bicep targetPosition.    "letzte Soll-Position"
bicep minValue.          "unteres Limit (Konfiguration)"
bicep maxValue.          "oberes Limit"
bicep restValue.         "Ruheposition"
bicep velocity.          "aktuelle Geschwindigkeit"
bicep isEnabled.         "Servo aktiviert?"
bicep isInverted.        "Richtung invertiert?"

"Steuern"
bicep setVelocity: 30.   "Grad/Sekunde"
bicep enable.
bicep disable.
bicep rest.              "in Ruheposition fahren"

"Alles auf einmal"
bicep statusDictionary.  "→ Dictionary mit allen obigen Werten"
```

---

## 7. Ruhepositionen — drei Ebenen

```smalltalk
(robot leftArm servoNamed: #shoulder) rest.   "ein Servo"
robot rightHand rest.                          "eine Gruppe"
robot restAll.                                 "der ganze Roboter"
```

`rest` fährt in die konfigurierte Ruheposition (`restValue`), nicht auf 0.

---

## 8. Geschwindigkeit

```smalltalk
robot leftArm setVelocity: 25.               "ganze Gruppe"
robot head servoNamed: #rothead setVelocity: 60.
```

Einheit: Grad pro Sekunde. Kleine Werte = langsame, sanfte Bewegungen.

---

## 9. Status und Konfiguration auslesen

```smalltalk
"Eine Gruppe komplett:"
robot head statusReport.
"→ Dictionary: #neck -> (#position->90.0, #targetPosition->90.0, #minValue->..., ...)"

"Den ganzen Roboter:"
report := robot statusReport.                  "Dictionary: #head/#leftArm/..."
(report at: #leftArm at: #bicep) at: #targetPosition.

"Nur eine Zahl, synchron:"
robot client numberAt: 'i01.head.rothead' method: 'getPos'.
"→ 90.0   (nil, wenn MRL null liefert)"
```

`statusReport`/`statusDictionary` sind **synchron**: Sie blockieren, bis alle Antworten da sind. Für eine UI daher in einem Hintergrundprozess pollen (siehe Kapitel 12).

---

## 10. Gesten abspielen

Gesten sind Python-Skripte im MRL-Verzeichnis `resource/InMoov2/gestures/`. Der Name ist der Dateiname plus `()`:

```smalltalk
robot performGesture: 'No()'.           "feuert ab und kehrt sofort zurück"
result := robot performGestureWait: 'No()'.   "blockt bis zum Ende der Geste"
```

Hinweise:

- Der **Python-Service muss laufen** (wird vom Projektstartskript gestartet). Läuft er nicht, passiert nichts und es kommt kein Fehler.
- `performGestureWait:` blockiert so lange wie die Geste dauert (Kopfschütteln ≈ 3 s) — ideal für Ablaufsteuerung, ungünstig innerhalb der UI.
- Skripte prüfen intern `runtime.isStarted(...)`: fehlende Teile (z. B. das neuere 4-Augen-Layout in `EyeMovements()`) werden stillschweigend übersprungen.
- Verfügbare Namen auflisten:

```bash
ls /pfad/zu/myrobotlab/resource/InMoov2/gestures/
```

---

## 11. Fehlerbehandlung und asynchrone Aufrufe

- Jeder nicht-erfolgreiche HTTP-Aufruf löst eine **`InmoovMrlError`** aus (enthält Statuscode und Antworttext).
- Synchronaufrufe (`position`, `statusReport`, `performGestureWait:` …) können daher `try/on:` brauchen.
- Fire-and-forget-Bewegungen (`moveTo…`) laufen in einem Hintergrundprozess; dort auftretende Fehler landen im Transkript und brechen die UI nicht.

```smalltalk
[
	robot performGestureWait: 'LookAtTheSky()'
] on: InmoovMrlError do: [ :ex |
	Transcript showln: 'Geste fehlgeschlagen: ', ex messageText ].
```

Eigener Polling-Loop (Muster aus dem Demo-Fenster):

```smalltalk
[
	[ (Delay forMilliseconds: 700) wait.
	  | pos |
	  pos := robot leftArm servoNamed: #bicep position.
	  UISupervisor whenUIinSafeState: [ statusLabel contents: pos printString ] ] repeat
] forkAt: Processor userBackgroundPriority
```

---

## 12. Das Demo-Fenster (`Inmoov-Demo.pck.st`)

```smalltalk
InmoovServoDemoWindow openOn: (InmoovRobot host: 'localhost' port: 8888 robotName: 'i01').
```

- Gruppenbuttons: L-Arm, R-Arm, L-Hand, R-Hand, Kopf, Torso — die Fensterhöhe passt sich der Zeilenzahl an.
- Pro Servo eine Zeile: **Wertfeld + Slider** (Servoname steht im Slider). Min/Max kommen aus der Live-Konfiguration, Startwert ist die Ruheposition.
- Ziehen sendet kontinuierlich (~120 ms Abstand), Loslassen garantiert den Endwert.
- Buttons „Rest Gruppe" / „Rest ALLES"; Statuszeile pollt alle 700 ms die Ist-Positionen.

---

## 13. Direkter REST-Zugriff mit `InmoovMrlClient`

Für alles, was die Komfortklassen nicht abbilden:

```smalltalk
client := InmoovMrlClient host: 'localhost' port: 8888 robotName: 'i01'.

"Synchron: antwortet mit dem dekodierten Body (String/Float/true/false/nil)"
client getSync: 'runtime' method: 'getUptime' args: #().
client getSync: 'i01.leftArm.bicep' method: 'getPos' args: #().
client getSync: 'i01.head.rothead' method: 'moveTo'
	args: #(90 130 90 110 10 90).        "Reihenfolge: neck,rothead,eyeX,eyeY,jaw,rollNeck"

"Asynchron (Hintergrundprozess):"
client callService: 'i01' method: 'rest' args: #().

"Bequeme Zahlen-/Boolean-Leses (null-sicher):"
client numberAt: 'i01.rightHand.index' method: 'getVelocity'.   "→ nil statt Crash"
client booleanAt: 'i01.rightHand.index' method: 'isEnabled'.
```

Zuordnung Smalltalk ↔ REST:

| Smalltalk-Aufruf | HTTP |
|---|---|
| `getSync: s method: m args: a` | `GET /api/service/{s}/{m}/{a…}` |
| `callService: …` (= fire&forget von `getSync`) | dito, aber im Fork |
| `uptime` | `GET /api/service/runtime/getUptime` |

---

## 14. Bekannte Besonderheiten und Fehlerbehebung

| Symptom | Ursache / Lösung |
|---|---|
| `Connection refused` | MRL läuft nicht oder falscher Port. `curl http://localhost:8888/api/service/runtime/getUptime` testen. |
| `isAvailable` → false | i01 nicht gestartet bzw. Peer-Gruppen fehlen. |
| Bewegung passiert nicht | `targetPosition` prüfen: Wenn sie stimmt, fährt der Servo (virtual mode bewegt nichts Sichtbares). |
| Geste wirkt nicht | Python-Service gestartet? Geste benötigt evtl. nicht vorhandene Services (stiller Skip, siehe Kap. 11). |
| MRL-Fehler „could not invoke … (double)" | Bekannter MRL-Bug bei Integer/null-Parametern — unsere Gruppen-API umgeht ihn bereits. |
| `velocity` liefert nil | Manche Augen-Servos melden `null`; `numberAt:` wandelt das sicher in `nil`. |

---

## 15. Anhang — API-Referenz kompakt

**InmoovRobot**
`host:port:robotName:` (Klasse) · `client:` (DI für Tests) ·
`leftArm rightArm leftHand rightHand head torso` ·
`restAll` · `isAvailable` · `uptime` · `statusReport` ·
`performGesture:` · `performGestureWait:`

**InmoovServoGroup**
`servoNamed:` · `moveToArgs:` ·
`moveToBicep:rotate:shoulder:omoplate:` ·
`moveToThumb:index:majeure:ringFinger:pinky:` (+ `wrist:`) ·
`moveToNeck:rotHead:` · `moveToNeck:rotHead:rollNeck:` · `moveToEyeX:eyeY:` ·
`moveToTopStom:midStom:lowStom:` ·
`rest` · `setVelocity:` · `statusReport` · `kind` · `groupName`

**InmoovServo**
`moveTo:` · `rest` · `setVelocity:` · `enable` · `disable` ·
`position` · `targetPosition` · `minValue` · `maxValue` · `restValue` ·
`velocity` · `isEnabled` · `isInverted` · `statusDictionary`

**InmoovMrlClient**
`host:port:robotName:` (Klasse) · `getSync:method:args:` · `callService:method:args:` ·
`numberAt:method:` · `booleanAt:method:` · `uptime` · `host` · `port` · `robotName`

**InmoovMrlError** — Ausnahmeklasse für alle REST-Fehler.
