# TuitionLuma Growth Intelligence Admin Setup

Private dashboard route:

- `/admin/growth/`

The route is not linked from public pages, is not included in `sitemap.xml`, and includes `noindex,nofollow,noarchive`.

## Local Preview

Static UI only:

```bash
cd Website
python3 -m http.server 8081
```

Cloudflare Pages Functions locally:

```bash
cd Website
npx wrangler pages dev . --compatibility-date=2026-06-26
```

## Access Control

Recommended production setup:

- Protect `/admin/*` with Cloudflare Access.
- Set `GROWTH_ADMIN_TOKEN` as a Cloudflare Pages environment variable.
- The dashboard API requires the token through the `x-admin-token` header when `GROWTH_ADMIN_TOKEN` is configured.

## Required Environment Variables

Admin:

- `GROWTH_ADMIN_TOKEN`
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

Each provider returns an empty state when credentials are missing or a provider has no data yet.

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

Cloudflare Pages will serve static files and the `/api/growth` Pages Function.

## Scheduled Jobs

The provider layer is designed so scheduled jobs can later call the same provider classes to refresh:

- Search Console
- Google Analytics
- Cloudflare Analytics
- App Store Connect
- App Reviews
- SEO analysis
- AI recommendations
