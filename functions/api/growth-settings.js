const PROVIDERS = [
  {
    key: "searchConsole",
    name: "Google Search Console",
    statusLabel: "Search performance",
    authentication: "Google OAuth refresh token",
    setupTimeMinutes: 15,
    refreshIntervalMinutes: 60,
    credentials: [
      {
        label: "Google OAuth Client",
        variables: ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET"],
        howToCreate: "Create an OAuth client in Google Cloud and enable Search Console API.",
        setupTimeMinutes: 10
      },
      {
        label: "Google OAuth Refresh Token",
        variables: ["GOOGLE_REFRESH_TOKEN"],
        howToCreate: "Authorize a Google account that can access TuitionLuma's Search Console property.",
        setupTimeMinutes: 5
      },
      {
        label: "Search Console Property",
        variables: ["GOOGLE_SEARCH_CONSOLE_SITE_URL"],
        howToCreate: "Add or verify the TuitionLuma website property in Google Search Console.",
        setupTimeMinutes: 5
      }
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
    setupTimeMinutes: 15,
    refreshIntervalMinutes: 30,
    credentials: [
      {
        label: "Google OAuth Client",
        variables: ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET"],
        howToCreate: "Use the same OAuth client used for Search Console.",
        setupTimeMinutes: 3
      },
      {
        label: "Google OAuth Refresh Token",
        variables: ["GOOGLE_REFRESH_TOKEN"],
        howToCreate: "Authorize a Google account that can access the TuitionLuma GA4 property.",
        setupTimeMinutes: 5
      },
      {
        label: "GA4 Property",
        variables: ["GA4_PROPERTY_ID"],
        howToCreate: "Copy the numeric property ID from Google Analytics Admin.",
        setupTimeMinutes: 5
      }
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
    setupTimeMinutes: 8,
    refreshIntervalMinutes: 15,
    autoDetected: [
      "Pages deployment URL",
      "Request origin",
      "Current Pages project runtime"
    ],
    credentials: [
      {
        label: "Cloudflare Analytics Token",
        variables: ["CLOUDFLARE_API_TOKEN"],
        howToCreate: "Create an API token with Analytics Read access for the TuitionLuma zone.",
        setupTimeMinutes: 5
      },
      {
        label: "Cloudflare Zone",
        variables: ["CLOUDFLARE_ZONE_TAG"],
        howToCreate: "Use the TuitionLuma zone ID from the Cloudflare dashboard.",
        setupTimeMinutes: 3
      }
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
    setupTimeMinutes: 20,
    refreshIntervalMinutes: 360,
    credentials: [
      {
        label: "App Store Connect API Key",
        variables: ["APP_STORE_CONNECT_KEY_ID", "APP_STORE_CONNECT_ISSUER_ID", "APP_STORE_CONNECT_PRIVATE_KEY"],
        howToCreate: "Create an API key in App Store Connect with access to TuitionLuma.",
        setupTimeMinutes: 10
      },
      {
        label: "TuitionLuma App",
        variables: ["APP_STORE_APP_ID"],
        howToCreate: "Copy the TuitionLuma app ID from App Store Connect.",
        setupTimeMinutes: 3
      },
      {
        label: "Sales and Trends Vendor",
        variables: ["APP_STORE_VENDOR_NUMBER"],
        howToCreate: "Copy the vendor number from App Store Connect Sales and Trends.",
        setupTimeMinutes: 5
      }
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
    setupTimeMinutes: 12,
    refreshIntervalMinutes: 360,
    credentials: [
      {
        label: "App Store Connect API Key",
        variables: ["APP_STORE_CONNECT_KEY_ID", "APP_STORE_CONNECT_ISSUER_ID", "APP_STORE_CONNECT_PRIVATE_KEY"],
        howToCreate: "Use the same App Store Connect API key configured for app performance.",
        setupTimeMinutes: 10
      },
      {
        label: "TuitionLuma App",
        variables: ["APP_STORE_APP_ID"],
        howToCreate: "Copy the TuitionLuma app ID from App Store Connect.",
        setupTimeMinutes: 3
      }
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
    setupTimeMinutes: 0,
    refreshIntervalMinutes: 60,
    autoDetected: [
      "Request origin",
      "Cloudflare Pages URL",
      "sitemap.xml",
      "robots.txt",
      "Generated page locations"
    ],
    setup: [
      "Set SITE_ORIGIN to the production TuitionLuma Pages URL.",
      "No third-party credentials are required."
    ]
  }
];

export async function onRequestGet(context) {
  const { request, env } = context;
  const requestUrl = new URL(request.url);
  const origin = env.SITE_ORIGIN || ((requestUrl.hostname === "localhost" || requestUrl.hostname === "127.0.0.1") ? requestUrl.origin : env.CF_PAGES_URL) || requestUrl.origin;
  const providers = PROVIDERS.map(provider => {
    const credentials = (provider.credentials || []).map(credential => ({
      ...credential,
      configured: credential.variables.every(name => Boolean(env[name]))
    }));
    const variables = credentials.flatMap(credential => credential.variables).map(name => ({
      name,
      configured: Boolean(env[name])
    }));
    const configured = provider.key === "performance" || credentials.every(credential => credential.configured);
    return {
      ...provider,
      status: configured ? "Connected" : "Connect",
      health: configured ? "Connected" : "Missing credentials",
      configured,
      lastSuccessfulRefresh: null,
      currentStatus: configured ? "Ready for sync" : "Waiting for setup",
      autoDetectedValues: provider.key === "performance" ? {
        siteOrigin: origin.replace(/\/$/, ""),
        sitemap: `${origin.replace(/\/$/, "")}/sitemap.xml`,
        robots: `${origin.replace(/\/$/, "")}/robots.txt`
      } : {},
      credentials,
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
