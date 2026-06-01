# Döner Empire 3D — Unity-Projekt (in Aufbau)

Dieser Ordner wird das **Unity-3D-Rewrite** von Döner Empire. Siehe Masterplan:
[../docs/UNITY_REWRITE_PLAN.md](../docs/UNITY_REWRITE_PLAN.md).

## Status
Frühe Foundation-Phase (Meilenstein M1 — Daten-Layer).

> ⚠️ **Noch kein vollständiges Unity-Projekt.** `ProjectSettings/`, `Packages/`
> und die `.meta`-Dateien werden vom Unity-Editor beim einmaligen Anlegen
> erzeugt — das geht nicht ohne installierten Editor.
>
> ⚠️ **Der C#-Code hier ist noch nicht kompiliert/getestet** (kein Unity, kein
> .NET SDK auf der Build-Maschine). Es ist eine sorgfältige, review-fähige
> Portierung der vollständig gelesenen Dart-Quellen aus `../lib/`.

## Setup (einmalig, durch den Owner)
1. Unity Hub + **Unity 6 LTS** installieren (Android-Modul).
2. Neues Projekt: Template **3D (URP) Mobile**, Speicherort = **dieser `unity/`-Ordner**.
   (Falls Unity nicht in einen nicht-leeren Ordner anlegen will: in einem
   temporären Ordner anlegen, dann `Assets/`, `Packages/`, `ProjectSettings/`
   hierher verschieben — die bestehenden `Assets/Scripts/` einfach behalten.)
3. **.NET 8 SDK** installieren (für `dotnet test` der Logik außerhalb Unitys).
4. **Git LFS** aktivieren für `Assets/Art/**` (Modelle/Texturen).

## Ordnerstruktur (Ziel)
```
Assets/Scripts/Core         Enums, Konstanten, Utils  (UnityEngine-frei)
Assets/Scripts/Models       Daten-Klassen             (UnityEngine-frei)
Assets/Scripts/Data         Spiel-Daten (Städte, Produkte, …)
Assets/Scripts/Simulation   Engines (Port der lib/services)
Assets/Scripts/Save         JSON-Speicher (kompatibel zu Flutter-Save)
Assets/Scripts/View3D       City-Map-Szene
Assets/Scripts/UI           UI-Toolkit-Screens (Premium-Theme)
Assets/Scripts/App          Bootstrapping & Flow
```

## Bereits angelegt (M1-Start)
- `Assets/Scripts/Core/Enums.cs`
- `Assets/Scripts/Models/DifficultyModel.cs`
- `Assets/Scripts/Data/GameData.cs` (Städte + Produkte)

## Wichtig: Save-Kompatibilität
JSON-Feldnamen und Enum-String-Werte **exakt wie in Flutter** halten
(Dart `enum.name` ist camelCase, z.B. `cheapMass`, `klein`, `touristic`).
C#-Enums sind PascalCase — beim (De)Serialisieren ist ein Mapping auf die
Dart-Strings nötig (siehe Kommentare in `Enums.cs`). So bleiben bestehende
Spielstände ladbar und die Logik 1:1 gegen die Flutter-Tests verifizierbar.
