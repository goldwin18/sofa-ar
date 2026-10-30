# Sofa AR

Customers pick a sofa, tap **View in your room**, point the phone at the floor, and see the sofa
standing there in real size. Works with 10 sample sofas, and you can add your own sofa photos.

## Features

| Feature | What it does |
|---|---|
| **3D viewer** | Rotate any sofa with your finger. |
| **View in your room (AR)** | Button inside the viewer. Opens Google's AR viewer (ARCore), places the sofa on the floor at true size. Same idea as Amazon's feature. |
| **Camera overlay** | Opens the live camera with the sofa picture on top. Drag, pinch to resize, twist to rotate, flip, swap sofas, and share a screenshot. Works on every phone and with any photo. |
| **10 sample sofas** | Real sofa photos (background removed) + a real-size `.glb` for each in `assets/`. The sample `.glb` files are flat photo cut-outs, not full 3D shapes. |
| **Add your own sofa** | Pick a photo, plain background is removed automatically, set name / price / real width. |
| **Convert to 3D** | Two options: *Quick 3D cut-out* (offline, flat) or *AI 3D model* (Meshy API, full model, needs a key). |

## Build the APK

**Easiest (no setup): GitHub Actions**
1. Create a GitHub repo and push this folder.
2. Open the repo's **Actions** tab, run **Build APK** (it also runs on every push).
3. Download `sofa-ar-apk` from the run's Artifacts, unzip, install `app-release.apk`.

**On your computer** (Flutter installed):
```bash
./setup.sh                      # creates android/, patches it, runs pub get
flutter run                     # run on a connected phone
flutter build apk --release     # build/app/outputs/flutter-apk/app-release.apk
```

## Making "View in your room" work

Google's AR viewer only loads models from a **public https link**, so the sample `.glb` files are
served from this GitHub repo through jsDelivr:

`https://cdn.jsdelivr.net/gh/goldwin18/sofa-ar@main/assets/models/sofa_01.glb`

- The repo must be **public** (or change `hostedModelsBaseUrl` in `lib/core/constants/app_constants.dart`
  to wherever you host the models).
- Open that link in a browser to check: it should download the file. jsDelivr can take a few minutes to
  see new commits, and keeps `@main` cached for up to ~12 hours.
- Models you create inside the app live only on the phone, so AR is not available for them until
  there is somewhere to upload them (planned with the backend step).

## Phone requirements for AR
Android 8+ with **Google Play Services for AR** (ARCore). Most phones from the last few years have it.
If the AR button doesn't show, the phone doesn't support ARCore; use the camera overlay instead.

## Code layout

```
lib/
  main.dart, app.dart                 start-up, providers, theme
  core/                               shared pieces used by every screen
    constants/  theme/  utils/  widgets/
  data/                               Sofa model, the 10 samples, saved-sofa repository
  services/                           things that do work (no UI)
    image_to_3d/                      converters: cutout (offline) + Meshy (AI)
    glb_builder.dart  glb_scaler.dart background_remover.dart  settings_service.dart
  features/                           one folder per screen
    home/  detail/  camera_overlay/  add_sofa/  settings/
assets/models/*.glb   assets/images/*.png
tool/                                 patch_android.py, make_sample_sofas.py
```

## Common tasks

- **Add a sample sofa:** put `sofa_11.glb` in `assets/models/`, `sofa_11.png` in `assets/images/`, add one line in `lib/data/sample_sofas.dart`.
- **Better sofa models:** replace any `.glb` in `assets/models/` with a real scanned/designed model. Keep the same file name. Models should be in metres.
- **Change a sample photo:** replace `assets/images/sofa_XX.png` (transparent background), then run `python3 tool/make_sample_glbs.py` to rebuild its `.glb`.
- **Add another 3D converter (Tripo, Luma, your own server):** implement `ImageTo3dService` and add it to `converter_registry.dart`.
- **Change colours:** `lib/core/theme/app_theme.dart`.

## Notes and limits

- The sample `.glb` files are flat, upright cut-outs of each photo (built by `tool/make_sample_glbs.py`), so they look right from the front but thin from the side. For a full 3D shape, convert the photo with the AI option (Meshy) and replace the `.glb` of the same name. Prices in `sample_sofas.dart` are placeholders.
- *Quick 3D cut-out* is a flat standing picture, not a real sofa shape. For a true 3D shape use the AI option.
- Background removal only handles plain white / light-grey backgrounds.
- The Meshy API key is stored on the phone. For a public release, route calls through your own server.
- AR scale is fixed so customers see the true size of the sofa.
