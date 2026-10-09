# Debug signing key (NOT a secret, NOT for release)

- `johnfoods-debug.p12`: stable debug keystore so every CI build has the
  SAME certificate, and therefore the SAME SHA-1 in Firebase.
  Password: `android`, alias: `androiddebugkey`.
  Debug keys are insecure by design (same as the default Android debug
  keystore on every dev machine). NEVER use for release builds.
- `debug.cer`: the public certificate. Its fingerprints:
  - SHA-1: C5:FE:E3:0D:41:C9:CB:38:30:0E:75:E2:7C:37:5A:37:6A:A1:59:61
  - SHA-256: 6D:4E:7A:0F:07:2D:A0:A4:6A:FB:F5:5A:1C:12:9A:DD:80:5E:DB:33:8A:53:62:9E:AE:60:39:A8:8D:53:F7:A5

Wiring CI to sign with this file (android/key.properties + build.gradle)
is a separate later task, done when you want Google Sign-In on debug APKs
or signed release builds.
