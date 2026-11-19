# SwiftHTML: Implementierungsbriefing

## Auftrag und Arbeitsweise

Baue in diesem lokalen Repository ein eigenständiges SwiftPM-Paket `SwiftHTML`.
Nimm den überprüfbaren, fixturefreien SwiftSoup-2.14.4-Quellstand als Backend und
lege darüber eine kleine, moderne Swift-API. Ziel ist ein funktionierendes Paket
mit eigenen aussagekräftigen Tests – kein vollständiger Parser-Neubau und kein
großes Browser- oder Framework-Projekt. Arbeite auf einem eigenen Feature-Branch.
Prüfe zuerst Arbeitsbaum, Branches und anwendbare `AGENTS.md`-Dateien; bestehende
Arbeit darf nicht überschrieben werden. Erfinde keine veröffentlichten Versionen.

Alles bleibt zunächst lokal. Kein Remote-Repository erstellen oder verändern,
kein Push, Merge, Tag oder Release ohne späteren ausdrücklichen Auftrag.
SwiftMD, SwiftSoup und andere Schwester-Repositories nicht ungefragt ändern.

## Ausgangsbasis und Herkunft

* SwiftSoup 2.14.4: `https://github.com/scinfu/SwiftSoup.git`, Commit
  `8397a860c6955924b584c50c5265c6aac0970015`, `Sources`-Tree
  `f8472ba94c5dd20e84cc531ff046e7ad1029cdfa`. Die Kopie liegt unter
  `Vendor/SwiftSoup`, enthält nur `Sources` und `LICENSE` sowie die von uns
  ergänzte Herkunftsdatei `UPSTREAM.json`, und ist bei Übergabe unverändert.
* `python3 Scripts/verify-upstream.py` prüft die lokale Dateiliste und Hashes;
  `--reference` vergleicht zusätzlich gegen den gepinnten Git-Stand. Prüfe die
  tatsächlichen öffentlichen Tags und den Lizenztext selbst erneut. Das
  `Package.swift` von 2.14.4 nennt keine externen Paketabhängigkeiten; prüfe
  das bei der Implementierung erneut.
* Der SwiftSoup-Upstream enthält sechs gespeicherte Drittseiten in seinem
  Testkorpus. Diese und andere ungeprüfte Upstream-Tests oder Fixtures nicht in
  dieses Repository oder eine Paketdistribution übernehmen. Eigene Testdaten
  selbst verfassen oder ihre Rechte und Herkunft vor Übernahme konkret prüfen.
  Die MIT-Lizenz und alle geltenden Copyright- und Drittanbieternotizen erhalten;
  auch die jsoup-Herkunft dokumentieren. Ein Checksummentest ist keine
  abschließende Rechteprüfung.

## API und erster Funktionsumfang

* SwiftPM-Library mit Swift-6-orientierter öffentlicher API; für den vendorten
  Backend-Code dessen tatsächlichen Kompilierungsmodus transparent angeben. Die
  neue öffentliche API soll nicht von SwiftSoup-Typen abhängig sein. Wähle einen
  eindeutig benannten internen Backend-Modulnamen, um mit einem von einer App
  unabhängig hinzugefügten SwiftSoup zu koexistieren; teste dies, sofern die
  separate Upstream-Abhängigkeit bewusst im isolierten Test verwendet wird.
* Biete zuerst HTML-Dokumente und -Fragmente parsen, Elemente mittels CSS-Selektor
  finden, Text/Attribute lesen und ändern sowie HTML ausgeben. Fehler und nicht
  unterstützte Fälle sollen klar und überprüfbar sein. Kleine konkrete Beispiele
  für die API sind erwünscht. Keine Netzwerk- oder Browser-Runtime voraussetzen.
* Mutierbare DOM-Objekte und Besitzverhältnisse explizit behandeln. Keine
  unbelegte Thread-Safety, Value-Semantik oder `Sendable`-Garantien ausgeben;
  `@unchecked Sendable` nicht bloß zur Unterdrückung von Diagnosefehlern nutzen.
  Swift-6-Sprachmodus der eigenen API und Backend-Grenze tatsächlich prüfen.
* Texte und Attribute korrekt escapen; den Unterschied zwischen Text und bewusst
  übergebenem Raw HTML dokumentieren. Parser, Selektoren und fremdes HTML sind
  keine pauschale Sanitization. Keine Zeit-, Speicher- oder Größenlimits
  behaupten, die nicht umgesetzt und getestet sind.

## Tests und Nachweise

Nutze eigene, ausführbare Tests für Dokumente und Fragmente, fehlerhaftes HTML,
Unicode, Entities, Attribute, Kommentare, CSS-Selektoren, DOM-Mutationen,
Escaping und Serialisierung. Teste insbesondere Duplikate und Reihenfolge, wenn
die API diese Eigenschaften zusichert. Ein minimales sauberes SwiftPM-Consumer-
Projekt muss das öffentliche Produkt importieren und ausführen können.
Prüfe Build und tatsächliche Ausführung auf den verfügbaren Plattformen;
macOS und Linux anstreben, andere nur bei tatsächlichem Lauf als getestet
ausweisen. Ein Cross-Build allein ist kein Laufzeitnachweis. Dokumentiere exakte
Versionen, Host, Ergebnisse, Skips und noch offene Grenzen.

## Spätere Prüfung mit SwiftMD – zunächst nur lesend

SwiftMD 1.0.0 ist öffentlich; der Release-Tag zeigte zuletzt auf
`68903e4f0773df52956bf30510969bdd212d7bbd`, sein `main` nach einem CI-Fix auf
`f413383991f4f572b70d5377d4764a74fb595b18`. Das sind historische Anker –
tatsächliche Stände erneut prüfen. SwiftMD verwendet derzeit SwiftSoup 2.11.3
als eigenes, nicht öffentliches `SwiftMDSoup`-Target für strukturierte HTML-
Blockverarbeitung. Es bewahrt speziell validierte SVG-Fragmente bytegetreu,
weil gewöhnliche HTML-Serialisierung SVG-Attribute wie `viewBox` verändern kann.

Untersuche nach funktionierendem SwiftHTML read-only, wie SwiftMD auf das
eigenständige Paket umgestellt werden könnte: keine zyklischen Abhängigkeiten,
keine unnötigen doppelten HTML-Parser, Core ohne optionale Abhängigkeiten,
unveränderter bytegleicher Standardpfad und explizite SVG-Vertrauensgrenze.
Vergleiche vorhandene SwiftMD-Tests und die Auswirkungen des Upgrades von
SwiftSoup 2.11.3 auf 2.14.4. Integration nicht als fertig behaupten, bevor sie
implementiert und mit realen SwiftMD-Tests und Browserdarstellung geprüft wurde.
Änderungen in SwiftMD erfolgen erst mit entsprechendem Auftrag.

## Abschluss

Dokumentiere API, Lizenz- und Herkunftsinventar, tatsächlich ausgeführte Tests,
Plattformen, Grenzen und den konkreten Vorschlag für die SwiftMD-Integration.
Keine vollständige HTML-/Browser-Konformität oder unabhängige Sicherheitsprüfung
ohne geeignete Nachweise behaupten.
