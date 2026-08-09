# Releasing BetBook (Android)

This repo ships a fully automated, signed-APK release pipeline. Push a version
tag and GitHub Actions builds a **signed release APK**, generates a changelog,
creates a **QR code** to download it, and publishes a **GitHub Release** with
all of it attached.

- Workflow: [`.github/workflows/release.yml`](../.github/workflows/release.yml)
- Signing config: [`android/app/build.gradle.kts`](../android/app/build.gradle.kts)
- Helper scripts: [`scripts/`](../scripts)

---

## How it fits together

```
bump pubspec version  ->  git tag vX.Y.Z  ->  push tag  ->  CI builds & signs APK
                                                              -> changelog from commits
                                                              -> QR of the APK URL
                                                              -> GitHub Release published
```

The signing credentials come from **one of two places**, resolved in
`android/app/build.gradle.kts`:

1. `android/key.properties` — used on local machines (git-ignored).
2. Environment variables — used in CI (`KEYSTORE_PATH`, `KEYSTORE_PASSWORD`,
   `KEY_ALIAS`, `KEY_PASSWORD`).

If neither is present, release builds fall back to the debug keys so
`flutter run --release` still works during development.

---

## One-time setup

### 1. Generate an upload keystore

Run whichever fits your shell. The keystore is written **outside** the repo and
must never be committed.

**Windows / PowerShell**
```powershell
./scripts/generate-keystore.ps1
```

**macOS / Linux / Git Bash**
```bash
chmod +x scripts/generate-keystore.sh
scripts/generate-keystore.sh
```

You will be prompted for a **keystore password** and a **key password** (they
can be the same). Remember both — you will need them for the secrets below.

> Back up the `.jks` file and both passwords somewhere safe (e.g. a password
> manager). If you lose them you cannot publish updates signed with the same
> key, and users would have to uninstall/reinstall to take a new signature.

### 2. Set the four GitHub secrets

Go to **Settings -> Secrets and variables -> Actions -> New repository secret**
and add:

| Secret              | Value                                                        |
| ------------------- | ------------------------------------------------------------ |
| `KEYSTORE_BASE64`   | base64 of your `.jks` file (command printed by the script)   |
| `KEYSTORE_PASSWORD` | the keystore password you chose                              |
| `KEY_PASSWORD`      | the key password you chose                                   |
| `KEY_ALIAS`         | the alias (default `upload`)                                 |

To produce the base64 blob:

```powershell
# Windows / PowerShell — copies straight to the clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME/betbook-upload-keystore.jks")) | Set-Clipboard
```
```bash
# Linux
base64 -w0 "$HOME/betbook-upload-keystore.jks" > keystore.base64.txt
# macOS
base64 "$HOME/betbook-upload-keystore.jks" | tr -d '\n' > keystore.base64.txt
```

### 3. (Optional) Configure local release builds

To build a signed APK on your own machine, create `android/key.properties`
(already git-ignored — **do not commit it**):

```properties
storeFile=/absolute/path/to/betbook-upload-keystore.jks
storePassword=your-keystore-password
keyAlias=upload
keyPassword=your-key-password
```

Then:

```bash
flutter build apk --release
```

---

## Cutting a release

Versioning follows Flutter's default: `pubspec.yaml`'s `version:` drives both
the Android `versionName` and `versionCode`. Format is `X.Y.Z+BUILD`, e.g.
`1.2.0+5` gives `versionName = 1.2.0` and `versionCode = 5`.

1. **Bump the version** in `pubspec.yaml`:
   ```yaml
   version: 1.1.0+2
   ```
   Increase the `+BUILD` number every release (Android rejects an APK whose
   `versionCode` is not higher than the installed one).

2. **Commit** the bump.

3. **Tag** it — the tag should match the version, prefixed with `v`:
   ```bash
   git tag v1.1.0
   git push origin main
   git push origin v1.1.0
   ```

4. Pushing the `v*` tag triggers the workflow. Watch it under the **Actions**
   tab. When it finishes, the **Releases** page has a new `BetBook v1.1.0`
   release with the signed APK, the QR code, and the changelog.

You can also trigger it manually from **Actions -> Release Android APK -> Run
workflow**, supplying the tag to build.

---

## Downloading via QR

Open the published release on GitHub. The release notes show a **QR code** that
encodes the direct download URL of the APK
(`.../releases/download/vX.Y.Z/betbook-vX.Y.Z.apk`). Scan it with your phone's
camera to download the APK, then open it to install.

> Android may ask you to allow **"Install unknown apps"** for the browser you
> downloaded with. That is expected for APKs installed outside the Play Store.

---

## What the pipeline does (reference)

| Step               | Detail                                                                 |
| ------------------ | ---------------------------------------------------------------------- |
| Trigger            | Push tag `v*`, or manual `workflow_dispatch` with a tag input          |
| Toolchain          | Java 17 (Temurin), Flutter `3.44.0` stable; pub + gradle cached        |
| Signing            | Keystore decoded from `KEYSTORE_BASE64`; signed via env vars in gradle |
| APK                | `flutter build apk --release` — **universal APK** (see below)          |
| Changelog          | `scripts/generate-changelog.sh` groups commits since the previous tag  |
| QR code            | `qrcode` npm CLI encodes the APK's direct download URL into a PNG      |
| Release            | `softprops/action-gh-release@v2` attaches APK + QR, uses changelog body |
| Permissions        | `contents: write` only                                                 |

### Why a universal APK (no `--split-per-abi`)

The whole point of the QR code is a **single** scan-and-install download. A
per-ABI split produces three APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) and
would force the user to know their device's architecture — or force us to pick
one QR arbitrarily. A universal APK is a bit larger but installs on any device
from one URL, which is the right trade-off for direct distribution. If size
becomes a concern later, switch to an **App Bundle (`.aab`) via the Play
Store**, which does per-device delivery without exposing ABI choices.

---

## Setup checklist

Copy-paste and tick as you go:

```
[ ] Ran scripts/generate-keystore.ps1 (or .sh) and saved the .jks + passwords
[ ] Added secret KEYSTORE_BASE64
[ ] Added secret KEYSTORE_PASSWORD
[ ] Added secret KEY_PASSWORD
[ ] Added secret KEY_ALIAS
[ ] (optional) Created android/key.properties for local signed builds
[ ] Bumped version: in pubspec.yaml (X.Y.Z+BUILD, higher build number)
[ ] Committed the bump
[ ] git tag vX.Y.Z && git push origin vX.Y.Z
[ ] Watched Actions -> Release Android APK succeed
[ ] Opened the new GitHub Release and scanned the QR to install
```
