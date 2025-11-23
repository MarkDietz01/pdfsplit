import io
import os
import sys
from datetime import datetime
from pathlib import Path

from flask import Flask, flash, redirect, render_template, request, send_file, url_for

from posterizer import PosterizationError, create_poster_pdf


def get_template_folder() -> str:
    """Return the correct template path for dev and bundled executables."""
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        return str(Path(sys._MEIPASS) / "templates")
    return str(Path(__file__).parent / "templates")


def create_app() -> Flask:
    app = Flask(__name__, template_folder=get_template_folder())
    app.secret_key = os.environ.get("SECRET_KEY", "dev-secret-key")

    @app.route("/", methods=["GET", "POST"])
    def index():
        if request.method == "POST":
            file = request.files.get("image")
            pages_across = request.form.get("pages_across", type=int, default=2)
            margin_mm = request.form.get("margin_mm", type=float, default=10.0)
            dpi = request.form.get("dpi", type=int, default=300)
            orientation = request.form.get("orientation", default="portrait")

            if not file or file.filename == "":
                flash("Upload eerst een afbeelding.")
                return redirect(url_for("index"))

            try:
                pdf_bytes = create_poster_pdf(
                    file.stream,
                    pages_across=pages_across,
                    margin_mm=margin_mm,
                    dpi=dpi,
                    orientation=orientation,
                )
            except PosterizationError as exc:
                flash(str(exc))
                return redirect(url_for("index"))

            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            download_name = f"poster-{timestamp}.pdf"
            return send_file(
                io.BytesIO(pdf_bytes),
                mimetype="application/pdf",
                as_attachment=True,
                download_name=download_name,
            )

        return render_template("index.html")

    return app


if __name__ == "__main__":
    flask_app = create_app()
    flask_app.run(host="0.0.0.0", port=8000, debug=True)
