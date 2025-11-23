"""Helper script to build a standalone executable with PyInstaller."""

from __future__ import annotations

import os
import sys
from pathlib import Path

try:
    import PyInstaller.__main__
except ImportError as exc:  # pragma: no cover - defensive import check
    raise SystemExit("PyInstaller is niet geïnstalleerd. Voer 'pip install PyInstaller' uit.") from exc


PROJECT_ROOT = Path(__file__).parent
TEMPLATES_DIR = PROJECT_ROOT / "templates"


def build() -> None:
    if sys.version_info >= (3, 13):
        raise SystemExit(
            "Gebruik Python 3.12 of 3.11 om de .exe te bouwen; Pillow levert nog geen wielen voor Python 3.13/3.14."
        )

    template_spec = f"{TEMPLATES_DIR}{os.pathsep}templates"
    PyInstaller.__main__.run(
        [
            str(PROJECT_ROOT / "app.py"),
            "--name",
            "poster-splitter",
            "--onefile",
            "--noconfirm",
            "--clean",
            "--add-data",
            template_spec,
        ]
    )


if __name__ == "__main__":
    build()
