const PROVIDERS = [
  {
    key: "searchConsole",
    name: "Google Search Console",
    statusLabel: "Search performance",
    authentication: "Google OAuth refresh token",
    refreshIntervalMinutes: 60,
    required: [
      "GOOGLE_CLIENT_ID",
      "GOOGLE_CLIENT_SECRET",
      "GOOGLE_REFRESH_TOKEN",
      "GOOGLE_SEARCH_CONSOLE_SITE_URL"
    ],
    setup: [
      "Enable the Google Search Console API in Google Cloud.",
      "Create an OAuth client and authorize an account with access to the TuitionLuma Search Console property.",
      "Store the refresh token and site URL as Cloudflare Pages environment variables."
    ]
  },
  {
    key: "analytics",
    name: "Google Analytics 4",
    statusLabel: "Website analytics",
    authentication: "Google OAuth refresh token",
    refreshIntervalMinutes: 30,
    required: [
      "GOOGLE_CLIENT_ID",
      "GOOGLE_CLIENT_SECRET",
      "GOOGLE_REFRESH_TOKEN",
      "GA4_PROPERTY_ID"
    ],
    setup: [
      "Enable the Google Analytics Data API in Google Cloud.",
      "Authorize an account with access to the TuitionLuma GA4 property.",
      "Store the GA4 property ID as a Cloudflare Pages environment variable."
    ]
  },
  {
    key: "cloudflare",
    name: "Cloudflare Analytics",
    statusLabel: "Edge analytics",
    authentication: "Cloudflare API token",
    refreshIntervalMinutes: 15,
    required: [
      "CLOUDFLARE_API_TOKEN",
      "CLOUDFLARE_ZONE_TAG"
    ],
    setup: [
      "Create a Cloudflare API token with Analytics Read access for the TuitionLuma zone.",
      "Store the zone tag and token as Cloudflare Pages environment variables."
    ]
  },
  {
    key: "appStore",
    name: "App Store Connect",
    statusLabel: "App performance",
    authentication: "App Store Connect ES256 JWT",
    refreshIntervalMinutes: 360,
    required: [
      "APP_STORE_CONNECT_KEY_ID",
      "APP_STORE_CONNECT_ISSUER_ID",
      "APP_STORE_CONNECT_PRIVATE_KEY",
      "APP_STORE_APP_ID",
      "APP_STORE_VENDOR_NUMBER"
    ],
    setup: [
      "Create an App Store Connect API key with access to TuitionLuma.",
      "Store the issuer ID, key ID, private key, app ID, and vendor number as Cloudflare Pages environment variables."
    ]
  },
  {
    key: "reviews",
    name: "App Reviews",
    statusLabel: "Ratings and reviews",
    authentication: "App Store Connect ES256 JWT",
    refreshIntervalMinutes: 360,
    required: [
      "APP_STORE_CONNECT_KEY_ID",
      "APP_STORE_CONNECT_ISSUER_ID",
      "APP_STORE_CONNECT_PRIVATE_KEY",
      "APP_STORE_APP_ID"
    ],
    setup: [
      "Use the same App Store Connect API key as the App Store provider.",
      "Confirm the API key can read customer reviews for the TuitionLuma app."
    ]
  },
  {
    key: "performance",
    name: "SEO Analyzer",
    statusLabel: "Site health",
    authentication: "Public TuitionLuma website crawl",
    refreshIntervalMinutes: 60,
    required: [
      "SITE_ORIGIN"
    ],
    setup: [
      "Set SITE_ORIGIN to the production TuitionLuma Pages URL.",
      "No third-party credentials are required."
    ]
  }
];

export async function onRequestGet(context) {
  const { env } = context;
  const providers = PROVIDERS.map(provider => {
    const variables = provider.required.map(name => ({
      name,
      configured: Boolean(env[name])
    }));
    const configured = variables.every(variable => variable.configured);
    return {
      ...provider,
      status: configured ? "Connected" : "Configuration Required",
      configured,
      lastSuccessfulRefresh: null,
      variables
    };
  });

  return new Response(JSON.stringify({
    generatedAt: new Date().toISOString(),
    providers
  }), {
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-robots-tag": "noindex, nofollow, noarchive"
    }
  });
}
