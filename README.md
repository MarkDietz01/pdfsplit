# Poster Split

Een kleine Flask-app waarmee je één afbeelding kunt omzetten naar een poster die uit meerdere A4-pagina's bestaat. Upload een foto, kies hoeveel pagina's je naast elkaar wilt, en download direct de PDF.

## Installatie

> Gebruik momenteel Python 3.12 (of 3.11). Nieuwere Python-versies zoals 3.14 hebben nog geen stabiele Pillow-builds, waardoor `pip install -r requirements.txt` kan mislukken.

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Gebruiken

```bash
python app.py
```

Open daarna http://localhost:8000 en upload een afbeelding. Kies het aantal pagina's naast elkaar, stel eventueel de marges en DPI bij, en download de gegenereerde PDF.

## Windows .exe bouwen

1. Open een terminal in de projectmap en activeer je virtuele omgeving.
2. Installeer PyInstaller (zit al in `requirements.txt`):

   ```bash
   pip install -r requirements.txt
   ```

3. Start de build met één commando dat automatisch Python 3.12 installeert (indien nodig) en de juiste versie gebruikt:

   ```powershell
   powershell -ExecutionPolicy Bypass -File build.ps1
   ```

Het script controleert of Python 3.12 beschikbaar is, installeert het zo nodig via winget of de officiële installer, zet een geïsoleerde virtuele omgeving op en draait `PyInstaller` om `dist/poster-splitter.exe` te maken. Omdat de templates automatisch worden meegepakt via het build-script, kun je het `.exe`-bestand direct distribueren en uitvoeren op Windows. Let op: bouw op Windows om een Windows `.exe` te krijgen.
