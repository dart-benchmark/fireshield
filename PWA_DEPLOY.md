# FireShield AI — PWA Deployment Guide

**App:** FireShield AI | EY  
**Package:** com.ey.fireshieldai  
**Version:** 1.0.0-demo  
**PWA Strategy:** offline-first (all assets pre-cached)

---

## Build

```bash
cd fire_audit_platform/demo_app

# Full offline PWA build
flutter build web --release --pwa-strategy=offline-first

# Output → build/web/
```

---

## Deploy to Vercel

### Option A — CLI (fastest)

```bash
# Install Vercel CLI once
npm i -g vercel

cd fire_audit_platform/demo_app

# First deploy (follow prompts)
vercel --prod

# Subsequent deploys
vercel --prod
```

Vercel auto-detects `vercel.json` in the project root:
- `outputDirectory: "build/web"` — serves the Flutter web build
- SPA rewrites configured — deep-links work
- Correct `Content-Type` for `manifest.json`
- Service worker headers with `no-cache` (critical for SW updates)
- Immutable cache for assets/icons/splash

### Option B — GitHub integration

1. Push repo to GitHub
2. Go to vercel.com → New Project → Import repo
3. Set:
   - **Framework:** Other
   - **Build command:** `flutter build web --release --pwa-strategy=offline-first`
   - **Output directory:** `build/web`
4. Deploy → Vercel handles CI/CD on every push

### Vercel env (if Flutter not in PATH on Vercel):

Add to Build Settings → Environment Variables:
```
FLUTTER_VERSION = 3.44.2
```
And add a `build` script in a `package.json`:
```json
{ "scripts": { "build": "flutter build web --release --pwa-strategy=offline-first" } }
```

---

## Deploy to Netlify

### Option A — Drag & Drop (instant, no account needed for testing)

1. Run `flutter build web --release --pwa-strategy=offline-first`
2. Go to **app.netlify.com/drop**
3. Drag and drop the `build/web` folder
4. Netlify gives you a live URL immediately
5. `_redirects` and `_headers` files inside `build/web` are auto-applied

### Option B — CLI

```bash
# Install once
npm i -g netlify-cli

# Deploy
cd fire_audit_platform/demo_app
flutter build web --release --pwa-strategy=offline-first
netlify deploy --prod --dir=build/web
```

### Option C — GitHub CI/CD

`netlify.toml` at project root handles everything:
- Build command, output directory, redirects, headers
- Push to GitHub → connect repo in Netlify dashboard → auto-deploy

---

## Install on Devices

### Android Chrome
1. Open the hosted URL in Chrome
2. Banner appears: **"Add FireShield AI to Home Screen"**
3. Tap **Install** → app icon appears on home screen
4. Launches in standalone mode (no browser chrome)

### iPhone / iPad Safari
1. Open the hosted URL in Safari (must be Safari, not Chrome)
2. Tap the **Share button** (box with arrow)
3. Tap **"Add to Home Screen"**
4. Name it **FireShield AI** → tap **Add**
5. App icon appears; launches fullscreen with custom splash screen

### iPad — Additional step
Same as iPhone. For best experience, rotate to portrait before installing.

---

## PWA Checklist

| Requirement | Status |
|-------------|--------|
| `manifest.json` with name, icons, theme | Done |
| 192×192 and 512×512 PNG icons | Done |
| Maskable icons (Android adaptive) | Done |
| `apple-touch-icon` (180×180) | Done |
| Apple splash screens (12 sizes) | Done |
| `apple-mobile-web-app-capable` meta | Done |
| `apple-mobile-web-app-status-bar-style` | Done |
| `theme-color` meta tag | Done |
| `viewport-fit=cover` (iPhone notch) | Done |
| HTTPS (required for SW + installability) | Vercel/Netlify auto-provide |
| Service worker with offline caching | Done (Flutter offline-first) |
| SPA routing / 404 → index.html | Done (`_redirects`, `vercel.json`) |
| `manifest.json` served with correct MIME | Done (headers config) |
| Service worker served with no-cache | Done (headers config) |

---

## Demo Credentials

| Role | Email | Facility |
|------|-------|----------|
| Safety Manager | rajesh.kumar@refineryco.in | Jamnagar Refinery |
| Safety Manager | meena.patel@cityhospital.in | City Hospital Ahmedabad |
| Auditor | priya.nair@auditcorp.in | Phoenix Mall Bengaluru |
| Platform Admin | admin@fireaudit.gov.in | All Facilities |
| Org Admin | vikram.mehta@phoenixmalls.com | Phoenix Facilities |
| Govt Officer | arjun.singh@mfd.gov.in | Maharashtra FD |

Password: any — demo mode, role is selected from bottom sheet after sign-in.

---

## Offline Behaviour

The `offline-first` PWA strategy pre-caches all Flutter assets in the service worker on first load. After that:
- App loads instantly from cache
- All screens work offline (no backend calls)
- Mock data is embedded in the Dart/JS bundle
- Only fresh cache check happens in background; user always sees cached version first
