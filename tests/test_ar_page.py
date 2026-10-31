"""Opens ar.html in a real browser (Chromium) the way the app does."""
import pytest

from test_models import IDS, revision


@pytest.mark.parametrize("sofa_id", IDS)
def test_every_sofa_loads_and_renders(open_page, sofa_id):
    page, errors = open_page(f"model={sofa_id}_r{revision()}&title=Test")
    page.wait_for_function("document.getElementById('viewer').loaded === true", timeout=30000)
    assert page.inner_text("#title") == "Test"
    assert errors == []


def test_unknown_model_shows_an_error_message(open_page):
    page, _ = open_page("model=does_not_exist")
    page.wait_for_function("document.getElementById('status').textContent.length > 0", timeout=15000)
    assert "could not be loaded" in page.inner_text("#status")


def test_no_model_given(open_page):
    page, _ = open_page("")
    assert "No model chosen" in page.inner_text("#status")


def test_desktop_browser_explains_that_ar_is_missing(open_page):
    page, _ = open_page(f"model=sofa_04_r{revision()}")
    page.wait_for_function("document.getElementById('viewer').loaded === true", timeout=30000)
    page.wait_for_function("document.getElementById('status').textContent.length > 0")
    assert "AR is not available" in page.inner_text("#status")


def test_page_asks_for_chromes_own_ar_before_googles_viewer(open_page):
    page, _ = open_page(f"model=sofa_04_r{revision()}")
    assert page.get_attribute("#viewer", "ar-modes").split() == ["webxr", "scene-viewer"]


def test_modes_parameter_can_force_a_route(open_page):
    page, _ = open_page(f"model=sofa_04_r{revision()}&modes=scene-viewer")
    assert page.get_attribute("#viewer", "ar-modes") == "scene-viewer"
    page, _ = open_page(f"model=sofa_04_r{revision()}&modes=nonsense")
    assert page.get_attribute("#viewer", "ar-modes").split() == ["webxr", "scene-viewer"]


def test_android_phone_shows_button_and_starts_chromes_ar_first(open_page):
    """With a fake WebXR: the AR button appears, and tapping it starts a WebXR AR session
    (the route that does not involve the Google app)."""
    page, _ = open_page(f"model=sofa_04_r{revision()}", android=True, xr=True)
    page.wait_for_function("document.getElementById('viewer').loaded === true", timeout=30000)
    page.wait_for_function("document.getElementById('viewer').canActivateAR === true", timeout=15000)
    assert page.is_visible(".ar-button")
    assert "AR is not available" not in page.inner_text("#status")

    page.click(".ar-button")
    page.wait_for_function("window.__xr.calls.length > 0", timeout=15000)
    call = page.evaluate("window.__xr.calls[0]")
    assert call["mode"] == "immersive-ar"
    assert "hit-test" in call["options"]["requiredFeatures"]  # needed to put the sofa on the floor


def test_failed_ar_start_is_reported_to_the_user(open_page):
    page, _ = open_page(f"model=sofa_04_r{revision()}")
    page.wait_for_function("document.getElementById('viewer').loaded === true", timeout=30000)
    page.evaluate("document.getElementById('viewer').dispatchEvent(new CustomEvent('ar-status', {detail: {status: 'failed'}}))")
    assert "could not start" in page.inner_text("#status")


def test_old_order_would_not_have_used_chromes_ar(open_page):
    """Control: with Google's viewer forced first, Chrome's own AR is NOT started. This is what the
    page did before, and why it hit the Google app crash."""
    page, _ = open_page(f"model=sofa_04_r{revision()}&modes=scene-viewer", android=True, xr=True)
    page.wait_for_function("document.getElementById('viewer').loaded === true", timeout=30000)
    page.wait_for_function("document.getElementById('viewer').canActivateAR === true", timeout=15000)
    page.click(".ar-button")
    page.wait_for_timeout(2500)
    assert page.evaluate("window.__xr.calls.length") == 0


def test_resizing_is_on_by_default_and_can_be_locked(open_page):
    page, _ = open_page(f"model=sofa_04_r{revision()}")
    assert page.get_attribute("#viewer", "ar-scale") == "auto"
    page, _ = open_page(f"model=sofa_04_r{revision()}&scale=fixed")
    assert page.get_attribute("#viewer", "ar-scale") == "fixed"
