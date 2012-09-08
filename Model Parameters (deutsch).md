Model parameters-Format
=======================

Diese Datei auch mal in Deutsch, weil ich weiß, dass es deutschsprachige Leute gibt, die mit diesem Format arbeiten können.

In XNALara sind sehr viele Werte fest im Programmcode eingebaut, was es unter anderem sehr schwierig gemacht hat, neue Modelle einzufügen. In GLLara sind diese Werte statt dessen in einzelnen .modelparams.plist-Dateien gespeichert. Im Augenblick ist das Ergebnis praktisch das Selbe, aber es ist in der Zukunft zum Beispiel einfach möglich, dass der Autor eines Modells seine eigene .modelparams.plist beifügt, die vielleicht auch ganz andere Shader haben kann.

Hier nun das Format.

Property List
-------------

Alle diese Dateien sind Apple Property List-Dateien (kurz Plist) und können mit jedem Plist-Editor bearbeitet werden. Es geht aber auch mit einem beliebigen Texteditor. Wer Plists schon kennt kann diesen Teil überspringen.

Plists tun ziemlich exakt genau das selbe wie JSON, und hatten früher sogar mal ein Format sehr ähnlich wie heutiges JSON, aber das wurde durch "moderneres" und deutlich schreiblastigeres XML ersetzt, lange bevor die JSON-Leute die guten Ideen von damals wiederentdeckt haben.

Der große Vorteil gegenüber JSON ist, dass es für einen OS X Entwickler überaus trivial ist, die Dinger einzulesen. Sie werden automatisch in die Array-, Dictionary-, String- und Number-Klassen umgewandelt.

Die Grundstruktur sieht so aus:

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	</plist>

Darin enthalten sind Dictionaries, Arrays, Strings, Nummern und theoretisch auch noch mehr, aber bei mir zumindest derzeit nicht.

Eine Nummer ist sehr einfach:

	<real>0.4</real>
	<integer>12</integer>

Eigentlich sollte man bei mir überall `<real>` verwenden. `<integer>` kann auch korrekt gelesen werden, so lange es sich um Ganzzahlen handelt.

Für Strings gibt es:

	<string>Dies ist ein Text</string>

Man kann eine Nummer auch in einen String packen (`<string>0.4</string>`), aber das ist schlechter Stil.

Ein Array ist einfach eine geordnete Liste von Objekten. Er kann auch weitere Arrays oder dictionaries enthalten, auch gemischt (wenn auch nicht hier).

	<array>
		<real>12</real>
		<string>hallo!</string>
		<dict>…</dict>
		<array>…</array>
		<real>0.8</real>
	</array>

Ein Dictionary ist eine Liste von Schlüsselwerten gefolgt von Objekten. Die Schlüssel werden in `<key>Eintrag</key>` gespeichert und sind immer String. Wie beim Array kann ein Objekt hier auch immer ein anderes Dictionary oder ein Array sein.

	<dict>
		<key>defaultRenderParameters</key>
		<dict>
			<key>bumpSpecularAmount</key>
			<real>0.1</real>
		</dict>
	</dict>

Die Reihenfolge der Paare in einem Dictionary ist absolut egal. Eine Plist-Datei enthält (hier) immer genau ein Dictionary direkt unter dem `<plist>`-Element.

Definieren von Modellen
-----------------------

Für jedes Modell, welches nicht das Generic Item-Format verwendet, muss es eine `modellname.modelparams.plist`-Datei geben, die von GLLara beim kompilieren eingebaut wird. Diese ist ein Dictionary mit ein bis fünf Keys: `base`, `meshGroupNames`, `defaultRenderParameters`, `renderParameters`, `cameraTargets`, `shaders` und `meshSplitters`.

Meshes oder Bones auf die sich hier bezogen wird müssen in einem Modell nicht existieren; dann werden Werte, die sich darauf beziehen, einfach ignoriert.

**Hinweis:** Ich hoffe, dass ich alle Modelle hiermit abdecken kann, aber es besteht eine gewisse Chance, dass dem nicht so ist. Wenn jemand ein Gegenbeispiel findet, bitte mir Bescheid sagen! (Aber nicht Generic Item. Das wird anders gehandelt).

### base

Ein String. Gibt den Namen einer anderen modelparams-Datei an (ohne die `.modelparams.plist`-Erweiterung), deren Werte auch mit verwendet werden sollen. Dies muss nicht vorhanden sein, aber in der Praxis wird jede Datei hier entweder `xnaLaraDefault` enthalten, oder eine Datei die dies als `base` hat, weil alle benötigten Shader dort enthalten sind. Wenn zwei Objekte die selben Parameter haben, von vorne bis hinten, dann kann auch bei einem von beiden einfach nur dieser Key vorhanden sein und auf die andere Datei zeigen.

Beispiel:

	…
	<key>base</key>
	<string>xnaLaraDefault</string>
	…

oder auch:

	…
	<key>base</key>
	<string>lara</string>
	…

### meshGroupNames

Ein Dictionary. Jeder Key ist der Name einer Mesh-Gruppe. Das Objekt ist dann ein Array von Namen von Meshes, die zu dieser Rendergruppe gehören. Ein Mesh kann zu mehreren Rendergruppen gehören, aber nur eine darf einen Shader haben, sonst ist das Ergebnis nicht definiert. Welcher Shader zu welchem Namen einer Rendergruppe gehört, wird im Key `Shakers` festgelegt.

Wichtig hier ist: Alle Standard Meshgruppen werden unterstützt, aber nicht für alle existieren schon Shader. Nur MeshGroup1 bis MeshGroup7 und MeshGroup10, sowie alle Gruppen, die die selben Shader unterstützen, werden hier unterstützt.

Beispiel:

	…
	<key>meshGroupNames</key>
	<dict>
		<key>MeshGroup1</key>
		<array>
			<string>mesh1</string>
			<string>mesh2</string>
		</array>
		<key>MeshGroup2</key>
		<array>
			<string>mesh4</string>
		</array>
		<key>MeshGroup8</key>
		<array>
			<string>mesh3</string>
		</array>
	</dict>
	…

### renderParameters

Ein Dictionary. Jeder Key ist der Name eines Meshes, jeder Wert ist ein Dictionary bestehend aus Namen von Renderparametern und deren Werten.

Das Setzen von Werten für Render Parameter geschieht in XNALara nur über Position, d.h. man setzt Wert 0 und hofft, dass irgendwo Code erkennt, dass man damit `bumpSpecularAmount` meinte. Das fand ich hässlich, daher werden hier die Werte per Namen gesetzt. Welcher Namen bei welchem Shader zu welchem Parameter gehört steht in `Render Parameters.md`.

Beispiel:

	…
	<key>renderParameters</key>
	<dict>
		<key>belts1</key>
		<dict>
			<key>bump1UVScale</key>
			<integer>16</integer>
			<key>bump2UVScale</key>
			<integer>16</integer>
			<key>bumpSpecularAmount</key>
			<real>0.1</real>
		</dict>
		<key>metal</key>
		<dict>
			<key>bumpSpecularAmount</key>
			<real>0.6</real>
		</dict>
	</dict>
	…

### defaultRenderParameters

Ein Dictionary. Jeder Key ist der Name eines Renderparameters, jeder Wert ist eine Nummer, die diesem zugewiesen wird.

Ein sehr typisches Muster in XNALara ist, dass erst mal alle für alle Meshe der erste Renderparameter auf den selben Wert gesetzt wird, und dann danach überschrieben. Dafür dient dieser Key. Hier werden renderParameter-Werte gesetzt, die verwendet werden, wenn für ein Mesh kein Wert angegeben wurde.

Beispiel:

	…
	<key>defaultRenderParameters</key>
	<dict>
		<key>bumpSpecularAmount</key>
		<real>0.1</real>
	</dict>
	…

### cameraTargets

Ein Dictionary. Jeder Key ist der Name eines neuen Kamerazieles, jeder Wert ist ein Array mit Bones, die das Kameraziel definieren.

Beispiel:

	…
	<key>cameraTargets</key>
	<dict>
		<key>body</key>
		<array>
			<string>root body</string>
		</array>
		<key>head</key>
		<array>
			<string>head jaws upper left 2</string>
			<string>head jaws upper left 1</string>
		</array>
	</dict>
	…

### defaultMeshGroup

**Eher selten gebraucht.** Ein String; gibt die MeshGroup an, die Meshes erhalten, die sonst noch keine haben.

### shaders

**Brauchen normale Modell-Dateien nicht.** Ein Dictionary; die Keys sind die Namen von Shakern, die Werte sind Dictionaries, die die Shader beschreiben.

Ein Shader hier ist immer GLSL mit Version 150. Wie die Shader aussehen kann sich noch ändern, daher gebe ich hier keine Dokumentation dafür. Ein Dictionary für einen Shader aber ist einfach:

*	`fragment`: String, Dateiname eines Fragment-Shaders.
*	`vertex`: String, Dateiname eines Vertex-Shaders.
*	`textures`: Array von Strangs. Die Namen der Uniforms der Textursampler, in der Reihenfolge, in der die entsprechenden Texturen im Mesh angegeben sind.
*	`Parameters`: Die Parameter, die von diesem Shader verwendet werden. Entspricht uniform-Werten. Diese sind für das Generic Item Format vorhanden, und müssen in der Reihenfolge sein, in der die Werte dort definiert werden (dies ist genau die selbe, die auch in `Render parameters.md` verwendet wird).
*	`solidMeshGroups`: Array von Strangs. Die Namen der Mesh Groups, die mit diesem Shader ohne Alpha Blendung gerändert werden sollen.
*	`alphaMeshGroups`: Array von Strangs. Die Namen der Mesh Groups, die mit diesem Shader mit Alpha Blendung gerändert werden sollen.

Jede Mesh Group sollte maximal einen Shader haben, egal ob mit oder ohne Alpha. Ansonsten ist das Ergebnis nicht definiert. (Praktisch wird einer der Shader zufällig ausgewählt. Das ist nicht-deterministisch und kann sich auch in einer Mesh-Gruppe vom einem zu anderen Mesh unterscheiden.)

Beispiel:

	…
	<key>shaders</key>
	<dict>
		<key>DiffuseLightmapBump3</key>
		<dict>
			<key>alphaMeshGroups</key>
			<array>
				<string>MeshGroup20</string>
			</array>
			<key>solidMeshGroups</key>
			<array>
				<string>MeshGroup1</string>
			</array>
			<key>textures</key>
			<array>
				<string>diffuseTexture</string>
				<string>lightmapTexture</string>
				<string>bumpTexture</string>
				<string>maskTexture</string>
				<string>bump1Texture</string>
				<string>bump2Texture</string>
			</array>
			<key>parameters</key>
			<array>
				<string>bumpSpecularAmount</string>
				<string>bump1UVScale</string>
				<string>bump2UVScale</string>
			</array>
			<key>fragment</key>
			<string>DiffuseLightmapBump3.fs</string>
			<key>vertex</key>
			<string>Bump.vs</string>
		</dict>
		…
	</dict>
	…

### meshSplitters

**Brauchen normale Modell-Dateien nicht.** Ein Dictionary; die Keys sind die Namen von zu teilenden Meshes; die Werte sind ein Array von Mesh-Splitter-Spezifikationen (siehe unten).

Dies ist mit großem Abstand der obskurste Teil. XNALara meint, dass exakt ein Mesh bei allen Lara-Modellen in drei Teile zu spalten ist. Na von mir aus, aber ich mache dass wenigstens etwas allgemeiner. Jedes Mesh kann einen oder mehrere Mesh Splitter haben. Ein Mesh Splitter beschreibt einen Teilbereich des Meshes. Beim Einlesen werden Meshes, die Splitter haben, geteilt, und dann gelöscht und durch ihre Teilstücke ersetzt.

Ein Splitter wird beschrieben durch ein Dictionary mit dem Key `Name` (der neue Name des Teilstücks) und `{max,min}{X,Y,Z}`, jeweils Nummern mit dem entsprechenden Wert. Es müssen nicht alle angegeben werden; standardmäßig wird für `min` negative und für `max` positive Unendlichkeit angenommen.

Sachen wie Render-Parameter sind auf die Teilmeshes anzuwenden, nicht auf das Original!

Verwendet wird dies von der `lara`-Datei und allen, die davon abgeleitet sind.

Beispiel (das einzige, dass es je geben wird):

	…
	<key>meshSplitters</key>
	<dict>
		<key>thorwireframe</key>
		<array>
			<dict>
				<key>maxX</key>
				<string>0</string>
				<key>minY</key>
				<real>1.25</real>
				<key>Name</key>
				<string>thorglowgauntletright</string>
			</dict>
			<dict>
				<key>minX</key>
				<string>0</string>
				<key>minY</key>
				<real>1.25</real>
				<key>Name</key>
				<string>thorglowgauntletleft</string>
			</dict>
			<dict>
				<key>maxY</key>
				<real>1.25</real>
				<key>Name</key>
				<string>thorglowbelt</string>
			</dict>
		</array>
	</dict>
	…
