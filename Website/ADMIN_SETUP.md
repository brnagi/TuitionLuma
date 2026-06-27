# TuitionLuma Growth Intelligence Admin Setup

Private dashboard route:

- `/admin/growth/`
- `/admin/settings/`

The route is not linked from public pages, is not included in `sitemap.xml`, and includes `noindex,nofollow,noarchive`.

## Local Preview

Static UI only:

```bash
cd Website
python3 -m http.server 8081
```

Cloudflare Pages Functions locally from the repository root:

```bash
npx wrangler pages dev Website --compatibility-date=2026-06-10
```

## Access Control

Recommended production setup:

- Set `GROWTH_ADMIN_USERNAME` and `GROWTH_ADMIN_PASSWORD` as Cloudflare Pages environment variables.
- The dashboard uses browser Basic Auth for `/admin/*`, `/api/growth`, and `/api/growth-settings`.
- Cloudflare Access can still be added later for stronger identity-based access.

## Required Environment Variables

Admin:

- `GROWTH_ADMIN_USERNAME`
- `GROWTH_ADMIN_PASSWORD`
- `SITE_ORIGIN=https://tuitionluma.pages.dev`

Google OAuth:

- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_REFRESH_TOKEN`

Google Search Console:

- `GOOGLE_SEARCH_CONSOLE_SITE_URL=https://tuitionluma.pages.dev/`

Google Analytics Data API:

- `GA4_PROPERTY_ID`

Cloudflare Analytics:

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ZONE_TAG`

App Store Connect:

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`
- `APP_STORE_APP_ID`
- `APP_STORE_VENDOR_NUMBER`

## OAuth Setup

Google:

1. Create an OAuth client in Google Cloud.
2. Enable Google Search Console API.
3. Enable Google Analytics Data API.
4. Authorize a Google account that has access to the TuitionLuma Search Console property and GA4 property.
5. Store the refresh token in `GOOGLE_REFRESH_TOKEN`.

Cloudflare:

1. Create an API token with Analytics Read access for the TuitionLuma zone.
2. Set `CLOUDFLARE_ZONE_TAG` to the zone ID.

App Store Connect:

1. Create an App Store Connect API key.
2. Grant access to the TuitionLuma app.
3. Store the private key content in `APP_STORE_CONNECT_PRIVATE_KEY`.
4. Set `APP_STORE_APP_ID` to the App Store Connect app ID.
5. Set `APP_STORE_VENDOR_NUMBER` to enable Sales and Trends app unit reports.

## Providers

- `GoogleSearchConsoleProvider`
- `GoogleAnalyticsProvider`
- `CloudflareAnalyticsProvider`
- `AppStoreConnectProvider`
- `ReviewProvider`
- `SEOAnalyzer`
- `AIAdvisor`

The SEO Analyzer auto-detects the current request origin, Cloudflare Pages URL, `sitemap.xml`, `robots.txt`, and generated page locations. External providers display guided `Connect` states until their official API credentials are added.

The settings wizard at `/admin/settings/` shows:

- Setup steps
- Completion percentage
- Estimated setup time
- Friendly missing credential labels
- Developer-only environment variable details

## Deployment

Cloudflare Pages settings:

- Framework preset: None
- Build command: blank
- Build output directory: `Website`
- Production branch: `main`

Deploy after setting environment variables:

```bash
git push origin main
```

Cloudflare Pages will serve static files and the `/api/growth` and `/api/growth-settings` Pages Functions.

## Scheduled Jobs

The provider layer is designed so scheduled jobs can later call the same provider classes to refresh:

- Search Console
- Google Analytics
- Cloudflare Analytics
- App Store Connect
- App Reviews
- SEO analysis
- AI recommendations
