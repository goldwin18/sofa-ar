"""Shared test helpers: project paths, a local web server and a browser."""
import functools
import http.server
import os
import threading
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / "assets/models"
IMAGES = ROOT / "assets/images"

ANDROID_CHROME = (
    "Mozilla/5.0 (Linux; Android 11; M2101K6I) AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/130.0.0.0 Mobile Safari/537.36"
)


class _QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


@pytest.fixture(scope="session")
def site():
    """The project folder served over http, like GitHub Pages serves it."""
    handler = functools.partial(_QuietHandler, directory=str(ROOT))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{server.server_address[1]}"
    server.shutdown()


@pytest.fixture(scope="session")
def browser():
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        b = p.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader",
                                    "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"])
        yield b
        b.close()


@pytest.fixture()
def open_page(browser, site):
    """open_page(query, android=False, xr=False) -> (page, console_errors, models_requested)

    android=True  pretends to be Chrome on an Android phone.
    xr=True       adds a fake WebXR (Chrome's built-in AR) that records start attempts in
                  window.__xr.calls, so we can see which AR route the page tries.
    """
    contexts = []

    def _open(query, android=False, xr=False):
        kwargs = {"viewport": {"width": 412, "height": 800}}
        if android:
            kwargs.update(user_agent=ANDROID_CHROME, is_mobile=True, has_touch=True)
        ctx = browser.new_context(**kwargs)
        contexts.append(ctx)
        if xr:
            ctx.add_init_script("""
                window.__xr = { calls: [] };
                // real Chrome on Android has these; model-viewer checks for them
                window.XRSession = class XRSession { requestHitTestSource() {} };
                Object.defineProperty(navigator, 'xr', { configurable: true, value: {
                  isSessionSupported: async (mode) => mode === 'immersive-ar',
                  requestSession: async (mode, options) => {
                    window.__xr.calls.push({ mode, options });
                    throw new Error('fake WebXR: no real AR in the test browser');
                  },
                  addEventListener() {}, removeEventListener() {},
                }});
            """)
        page = ctx.new_page()
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)

        local_js = os.environ.get("MODEL_VIEWER_JS")  # offline copy of the CDN script
        if local_js:
            page.route("**/model-viewer.min.js", lambda r: r.fulfill(
                content_type="text/javascript", body=Path(local_js).read_bytes()))
        page.goto(f"{site}/ar.html?{query}")
        return page, errors

    yield _open
    for c in contexts:
        c.close()
