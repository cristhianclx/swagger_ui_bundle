from pathlib import Path

import importlib.resources

swagger_ui_path: Path = importlib.resources.files("swagger_ui_bundle") / "vendor/swagger-ui-5.31.0"
