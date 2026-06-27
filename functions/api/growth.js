const DAY_MS = 24 * 60 * 60 * 1000;
const CACHE_TTL_SECONDS = 15 * 60;

export async function onRequestGet(context) {
  const { request, env } = context;
  const now = new Date().toISOString();

  if (request.url && !new URL(request.url).searchParams.has("refresh")) {
    const cached = await readCache(request);
    if (cached) return cached;
  }

  const dateRange = buildDateRange();
  const siteOrigin = env.SITE_ORIGIN || new URL(request.url).origin;
  const providers = [
    new GoogleSearchConsoleProvider(env, dateRange),
    new GoogleAnalyticsProvider(env, dateRange),
    new CloudflareAnalyticsProvider(env, dateRange),
    new AppStoreConnectProvider(env, dateRange),
    new ReviewProvider(env),
    new SEOAnalyzer(siteOrigin)
  ];

  const results = {};
  const statuses = [];

  await Promise.all(providers.map(async provider => {
    const result = await provider.safeFetch(now);
    results[provider.key] = result.data;
    statuses.push({
      key: provider.key,
      name: provider.name,
      configured: provider.isConfigured(),
      ok: result.ok,
      status: result.status,
      message: result.message,
      lastSuccessfulRefresh: result.lastSuccessfulRefresh,
      refreshIntervalMinutes: provider.refreshIntervalMinutes,
      requiredEnvironment: provider.requiredEnvironment()
    });
  }));

  const content = new ContentOpportunityAnalyzer(results.performance, results.searchConsole).build();
  const advisor = new AIAdvisor({ ...results, content }, statuses).build();
  const configured = statuses.filter(status => status.configured).length;

  const response = json({
    generatedAt: new Date().toISOString(),
    providerStatus: {
      configured,
      total: statuses.length,
      providers: statuses
    },
    searchConsole: results.searchConsole,
    analytics: results.analytics,
    cloudflare: results.cloudflare,
    appStore: results.appStore,
    reviews: results.reviews,
    content,
    performance: results.performance,
    advisor
  });

  await writeCache(request, response.clone());
  return response;
}

async function readCache(request) {
  if (!globalThis.caches) return null;
  const cache = caches.default;
  const cacheKey = cacheRequest(request);
  const response = await cache.match(cacheKey);
  if (!response) return null;
  return new Response(response.body, {
    status: response.status,
    headers: {
      ...Object.fromEntries(response.headers.entries()),
      "x-growth-cache": "HIT"
    }
  });
}

async function writeCache(request, response) {
  if (!globalThis.caches) return;
  const cache = caches.default;
  await cache.put(cacheRequest(request), response);
}

function cacheRequest(request) {
  const url = new URL(request.url);
  url.search = "";
  return new Request(url.toString(), { method: "GET" });
}

function json(payload, status = 200, cacheSeconds = CACHE_TTL_SECONDS) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": `private, max-age=${cacheSeconds}`,
      "x-robots-tag": "noindex, nofollow, noarchive"
    }
  });
}

function buildDateRange() {
  const end = new Date(Date.now() - DAY_MS);
  const start = new Date(end.getTime() - 27 * DAY_MS);
  const previousEnd = new Date(start.getTime() - DAY_MS);
  const previousStart = new Date(previousEnd.getTime() - 27 * DAY_MS);
  return {
    startDate: toDate(start),
    endDate: toDate(end),
    previousStartDate: toDate(previousStart),
    previousEndDate: toDate(previousEnd)
  };
}

function toDate(date) {
  return date.toISOString().slice(0, 10);
}

class Provider {
  constructor(key, name, options = {}) {
    this.key = key;
    this.name = name;
    this.refreshIntervalMinutes = options.refreshIntervalMinutes || 60;
    this.requiredEnv = options.requiredEnv || [];
  }

  isConfigured() {
    return false;
  }

  emptyData() {
    return {};
  }

  async fetchData() {
    return this.emptyData();
  }

  requiredEnvironment() {
    return this.requiredEnv.map(name => ({
      name,
      configured: Boolean(this.env?.[name])
    }));
  }

  async safeFetch(now) {
    if (!this.isConfigured()) {
      return {
        ok: false,
        status: "Configuration Required",
        message: "Configuration Required",
        lastSuccessfulRefresh: null,
        data: this.emptyData("Configuration Required")
      };
    }
    try {
      return {
        ok: true,
        status: "Connected",
        message: "Connected",
        lastSuccessfulRefresh: now,
        data: await this.fetchData()
      };
    } catch (error) {
      return {
        ok: false,
        status: "Connection Error",
        message: error.message,
        lastSuccessfulRefresh: null,
        data: this.emptyData(error.message)
      };
    }
  }
}

class GoogleOAuthProvider extends Provider {
  constructor(key, name, env, dateRange, options = {}) {
    super(key, name, {
      refreshIntervalMinutes: options.refreshIntervalMinutes || 60,
      requiredEnv: ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN", ...(options.requiredEnv || [])]
    });
    this.env = env;
    this.dateRange = dateRange;
  }

  hasGoogleOAuth() {
    return Boolean(this.env.GOOGLE_CLIENT_ID && this.env.GOOGLE_CLIENT_SECRET && this.env.GOOGLE_REFRESH_TOKEN);
  }

  async accessToken() {
    const body = new URLSearchParams({
      client_id: this.env.GOOGLE_CLIENT_ID,
      client_secret: this.env.GOOGLE_CLIENT_SECRET,
      refresh_token: this.env.GOOGLE_REFRESH_TOKEN,
      grant_type: "refresh_token"
    });
    const response = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body
    });
    const payload = await response.json();
    if (!response.ok) throw new Error(payload.error_description || payload.error || "Google OAuth failed.");
    return payload.access_token;
  }
}

class GoogleSearchConsoleProvider extends GoogleOAuthProvider {
  constructor(env, dateRange) {
    super("searchConsole", "Google Search Console", env, dateRange, {
      refreshIntervalMinutes: 60,
      requiredEnv: ["GOOGLE_SEARCH_CONSOLE_SITE_URL"]
    });
  }

  isConfigured() {
    return this.hasGoogleOAuth() && Boolean(this.env.GOOGLE_SEARCH_CONSOLE_SITE_URL);
  }

  emptyData(error) {
    return {
      clicks: null,
      impressions: null,
      ctr: null,
      position: null,
      topPages: [],
      topQueries: [],
      nearPageOneQueries: [],
      fastestGrowingPages: [],
      error
    };
  }

  async fetchData() {
    const token = await this.accessToken();
    const site = encodeURIComponent(this.env.GOOGLE_SEARCH_CONSOLE_SITE_URL);
    const baseUrl = `https://www.googleapis.com/webmasters/v3/sites/${site}/searchAnalytics/query`;
    const summary = await this.query(baseUrl, token, {});
    const pages = await this.query(baseUrl, token, { dimensions: ["page"], rowLimit: 20 });
    const queries = await this.query(baseUrl, token, { dimensions: ["query"], rowLimit: 25 });
    const previousPages = await this.query(baseUrl, token, {
      dimensions: ["page"],
      rowLimit: 100,
      startDate: this.dateRange.previousStartDate,
      endDate: this.dateRange.previousEndDate
    });

    const pageRows = mapSearchRows(pages.rows, "page");
    const previousMap = new Map(mapSearchRows(previousPages.rows, "page").map(row => [row.page, row.clicks]));
    const fastestGrowingPages = pageRows
      .map(row => ({ ...row, deltaClicks: row.clicks - (previousMap.get(row.page) || 0) }))
      .filter(row => row.deltaClicks > 0)
      .sort((a, b) => b.deltaClicks - a.deltaClicks)
      .slice(0, 10);

    return {
      clicks: summary.rows?.[0]?.clicks || 0,
      impressions: summary.rows?.[0]?.impressions || 0,
      ctr: summary.rows?.[0]?.ctr || 0,
      position: summary.rows?.[0]?.position || null,
      topPages: pageRows,
      topQueries: mapSearchRows(queries.rows, "query"),
      nearPageOneQueries: mapSearchRows(queries.rows, "query")
        .filter(row => row.position >= 8 && row.position <= 20)
        .sort((a, b) => a.position - b.position),
      fastestGrowingPages
    };
  }

  async query(url, token, options) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json"
      },
      body: JSON.stringify({
        startDate: options.startDate || this.dateRange.startDate,
        endDate: options.endDate || this.dateRange.endDate,
        dimensions: options.dimensions || [],
        rowLimit: options.rowLimit || 1
      })
    });
    const payload = await response.json();
    if (!response.ok) throw new Error(payload.error?.message || "Search Console query failed.");
    return payload;
  }
}

class GoogleAnalyticsProvider extends GoogleOAuthProvider {
  constructor(env, dateRange) {
    super("analytics", "Google Analytics Data API", env, dateRange, {
      refreshIntervalMinutes: 30,
      requiredEnv: ["GA4_PROPERTY_ID"]
    });
  }

  isConfigured() {
    return this.hasGoogleOAuth() && Boolean(this.env.GA4_PROPERTY_ID);
  }

  emptyData(error) {
    return {
      users: null,
      sessions: null,
      organicUsers: null,
      organicSessions: null,
      landingPages: [],
      trafficSources: [],
      conversionEvents: [],
      error
    };
  }

  async fetchData() {
    const token = await this.accessToken();
    const url = `https://analyticsdata.googleapis.com/v1beta/properties/${this.env.GA4_PROPERTY_ID}:runReport`;
    const totals = await this.runReport(url, token, {
      metrics: [{ name: "activeUsers" }, { name: "sessions" }],
      dimensions: []
    });
    const organic = await this.runReport(url, token, {
      metrics: [{ name: "activeUsers" }, { name: "sessions" }],
      dimensions: [{ name: "sessionDefaultChannelGroup" }],
      dimensionFilter: exactFilter("sessionDefaultChannelGroup", "Organic Search")
    });
    const landing = await this.runReport(url, token, {
      metrics: [{ name: "sessions" }, { name: "activeUsers" }],
      dimensions: [{ name: "landingPagePlusQueryString" }],
      limit: "10"
    });
    const sources = await this.runReport(url, token, {
      metrics: [{ name: "sessions" }],
      dimensions: [{ name: "sessionDefaultChannelGroup" }],
      limit: "10"
    });
    const conversions = await this.optionalReport(url, token, {
      metrics: [{ name: "keyEvents" }],
      dimensions: [{ name: "eventName" }],
      limit: "10"
    });

    return {
      users: metricValue(totals, 0, 0),
      sessions: metricValue(totals, 0, 1),
      organicUsers: metricValue(organic, 0, 0),
      organicSessions: metricValue(organic, 0, 1),
      landingPages: mapAnalyticsRows(landing.rows, "page", "sessions"),
      trafficSources: mapAnalyticsRows(sources.rows, "source", "sessions"),
      conversionEvents: mapAnalyticsRows(conversions.rows, "event", "keyEvents")
    };
  }

  async optionalReport(url, token, body) {
    try {
      return await this.runReport(url, token, body);
    } catch {
      return { rows: [] };
    }
  }

  async runReport(url, token, body) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json"
      },
      body: JSON.stringify({
        dateRanges: [{ startDate: this.dateRange.startDate, endDate: this.dateRange.endDate }],
        ...body
      })
    });
    const payload = await response.json();
    if (!response.ok) throw new Error(payload.error?.message || "Google Analytics query failed.");
    return payload;
  }
}

class CloudflareAnalyticsProvider extends Provider {
  constructor(env, dateRange) {
    super("cloudflare", "Cloudflare Analytics", {
      refreshIntervalMinutes: 15,
      requiredEnv: ["CLOUDFLARE_API_TOKEN", "CLOUDFLARE_ZONE_TAG"]
    });
    this.env = env;
    this.dateRange = dateRange;
  }

  isConfigured() {
    return Boolean(this.env.CLOUDFLARE_API_TOKEN && this.env.CLOUDFLARE_ZONE_TAG);
  }

  emptyData(error) {
    return {
      requests: null,
      cacheHitRate: null,
      bandwidth: null,
      topUrls: [],
      geographicTraffic: [],
      error
    };
  }

  async fetchData() {
    const query = `query ZoneAnalytics($zoneTag: string, $start: Date, $end: Date) {
      viewer {
        zones(filter: { zoneTag: $zoneTag }) {
          totals: httpRequests1dGroups(limit: 30, filter: { date_geq: $start, date_leq: $end }) {
            sum { requests bytes cachedBytes }
          }
          topUrls: httpRequestsAdaptiveGroups(limit: 10, filter: { datetime_geq: $start, datetime_leq: $end }, orderBy: [count_DESC]) {
            count
            dimensions { clientRequestPath }
          }
          countries: httpRequestsAdaptiveGroups(limit: 10, filter: { datetime_geq: $start, datetime_leq: $end }, orderBy: [count_DESC]) {
            count
            dimensions { clientCountryName }
          }
        }
      }
    }`;
    const payload = await this.graphql(query, {
      zoneTag: this.env.CLOUDFLARE_ZONE_TAG,
      start: this.dateRange.startDate,
      end: this.dateRange.endDate
    });
    const zone = payload.data?.viewer?.zones?.[0] || {};
    const totals = (zone.totals || []).reduce((acc, row) => {
      acc.requests += row.sum?.requests || 0;
      acc.bytes += row.sum?.bytes || 0;
      acc.cachedBytes += row.sum?.cachedBytes || 0;
      return acc;
    }, { requests: 0, bytes: 0, cachedBytes: 0 });
    return {
      requests: totals.requests,
      cacheHitRate: totals.bytes ? totals.cachedBytes / totals.bytes : null,
      bandwidth: totals.bytes,
      topUrls: (zone.topUrls || []).map(row => ({ url: row.dimensions.clientRequestPath, requests: row.count })),
      geographicTraffic: (zone.countries || []).map(row => ({ country: row.dimensions.clientCountryName, requests: row.count }))
    };
  }

  async graphql(query, variables) {
    const response = await fetch("https://api.cloudflare.com/client/v4/graphql", {
      method: "POST",
      headers: {
        authorization: `Bearer ${this.env.CLOUDFLARE_API_TOKEN}`,
        "content-type": "application/json"
      },
      body: JSON.stringify({ query, variables })
    });
    const payload = await response.json();
    if (!response.ok || payload.errors) throw new Error(payload.errors?.[0]?.message || "Cloudflare Analytics query failed.");
    return payload;
  }
}

class AppStoreConnectProvider extends Provider {
  constructor(env, dateRange) {
    super("appStore", "App Store Connect", {
      refreshIntervalMinutes: 360,
      requiredEnv: [
        "APP_STORE_CONNECT_KEY_ID",
        "APP_STORE_CONNECT_ISSUER_ID",
        "APP_STORE_CONNECT_PRIVATE_KEY",
        "APP_STORE_APP_ID",
        "APP_STORE_VENDOR_NUMBER"
      ]
    });
    this.env = env;
    this.dateRange = dateRange;
  }

  isConfigured() {
    return Boolean(
      this.env.APP_STORE_CONNECT_KEY_ID &&
      this.env.APP_STORE_CONNECT_ISSUER_ID &&
      this.env.APP_STORE_CONNECT_PRIVATE_KEY &&
      this.env.APP_STORE_APP_ID &&
      this.env.APP_STORE_VENDOR_NUMBER
    );
  }

  emptyData(error) {
    return {
      downloadsToday: null,
      downloadsThisWeek: null,
      productPageViews: null,
      productPageConversionRate: null,
      retentionRate: null,
      appUnits: null,
      territories: [],
      error
    };
  }

  async fetchData() {
    const token = await appStoreJwt(this.env);
    const reviews = await appStoreJson(`/v1/apps/${this.env.APP_STORE_APP_ID}/customerReviews?limit=1`, token);
    const sales = await this.fetchSalesReport(token);
    return {
      downloadsToday: sales.downloadsToday,
      downloadsThisWeek: sales.downloadsThisWeek,
      productPageViews: null,
      productPageConversionRate: null,
      retentionRate: null,
      appUnits: sales.appUnits,
      territories: sales.territories,
      reviewApiReachable: Boolean(reviews)
    };
  }

  async fetchSalesReport(token) {
    if (!this.env.APP_STORE_VENDOR_NUMBER) {
      return { downloadsToday: null, downloadsThisWeek: null, appUnits: null, territories: [] };
    }
    const reportDate = this.dateRange.endDate;
    const params = new URLSearchParams({
      "filter[frequency]": "DAILY",
      "filter[reportDate]": reportDate,
      "filter[reportSubType]": "SUMMARY",
      "filter[reportType]": "SALES",
      "filter[vendorNumber]": this.env.APP_STORE_VENDOR_NUMBER
    });
    const response = await fetch(`https://api.appstoreconnect.apple.com/v1/salesReports?${params}`, {
      headers: { authorization: `Bearer ${token}` }
    });
    if (!response.ok) return { downloadsToday: null, downloadsThisWeek: null, appUnits: null, territories: [] };
    const text = await response.text();
    const rows = parseTsv(text);
    const units = rows.reduce((sum, row) => sum + number(row.Units), 0);
    const territories = Object.values(rows.reduce((acc, row) => {
      const key = row["Country Code"] || "Unknown";
      acc[key] ||= { territory: key, downloads: 0 };
      acc[key].downloads += number(row.Units);
      return acc;
    }, {})).sort((a, b) => b.downloads - a.downloads).slice(0, 10);
    return { downloadsToday: units, downloadsThisWeek: null, appUnits: units, territories };
  }
}

class ReviewProvider extends Provider {
  constructor(env) {
    super("reviews", "App Reviews", {
      refreshIntervalMinutes: 360,
      requiredEnv: [
        "APP_STORE_CONNECT_KEY_ID",
        "APP_STORE_CONNECT_ISSUER_ID",
        "APP_STORE_CONNECT_PRIVATE_KEY",
        "APP_STORE_APP_ID"
      ]
    });
    this.env = env;
  }

  isConfigured() {
    return Boolean(this.env.APP_STORE_CONNECT_KEY_ID && this.env.APP_STORE_CONNECT_ISSUER_ID && this.env.APP_STORE_CONNECT_PRIVATE_KEY && this.env.APP_STORE_APP_ID);
  }

  emptyData(error) {
    return {
      averageRating: null,
      recentReviews: [],
      reviewTrends: [],
      sentimentSummary: "Configure App Store Connect to summarize recent reviews.",
      error
    };
  }

  async fetchData() {
    const token = await appStoreJwt(this.env);
    const payload = await appStoreJson(`/v1/apps/${this.env.APP_STORE_APP_ID}/customerReviews?limit=20&sort=-createdDate`, token);
    const reviews = (payload.data || []).map(item => ({
      title: item.attributes?.title,
      body: item.attributes?.body,
      rating: item.attributes?.rating,
      createdDate: item.attributes?.createdDate,
      territory: item.attributes?.territory
    }));
    const ratings = reviews.map(review => review.rating).filter(Boolean);
    const averageRating = ratings.length ? ratings.reduce((a, b) => a + b, 0) / ratings.length : null;
    return {
      averageRating,
      recentReviews: reviews,
      reviewTrends: [],
      sentimentSummary: summarizeSentiment(reviews)
    };
  }
}

class SEOAnalyzer extends Provider {
  constructor(siteOrigin) {
    super("performance", "SEO Analyzer", { refreshIntervalMinutes: 60 });
    this.siteOrigin = siteOrigin;
  }

  isConfigured() {
    return true;
  }

  emptyData(error) {
    return {
      largestImages: [],
      slowestPages: [],
      brokenLinks: [],
      missingMetadata: [],
      schemaStatus: [],
      error
    };
  }

  async fetchData() {
    const sitemap = await fetchText(`${this.siteOrigin}/sitemap.xml`);
    const urls = [...sitemap.matchAll(/<loc>(.*?)<\/loc>/g)].map(match => match[1]).slice(0, 80);
    const pages = await Promise.all(urls.map(async url => {
      const started = Date.now();
      const response = await fetch(url);
      const text = await response.text();
      return { url, text, durationMs: Date.now() - started, ok: response.ok };
    }));
    const missingMetadata = [];
    const schemaStatus = [];
    const brokenLinks = [];

    for (const page of pages) {
      const path = new URL(page.url).pathname;
      for (const [field, pattern] of Object.entries({
        title: /<title>.*?<\/title>/s,
        metaDescription: /<meta name="description"/,
        canonical: /rel="canonical"/,
        openGraph: /property="og:title"/,
        twitter: /name="twitter:card"/
      })) {
        if (!pattern.test(page.text)) missingMetadata.push({ page: path, field });
      }
      schemaStatus.push({ page: path, status: /application\/ld\+json/.test(page.text) ? "Structured data present" : "Missing structured data" });
      const hrefs = [...page.text.matchAll(/href="(\/[^"#]+)"/g)].map(match => match[1]).filter(href => !href.startsWith("/assets/") && href !== "/styles.css");
      for (const href of hrefs.slice(0, 40)) {
        const check = await fetch(`${this.siteOrigin}${href}`, { method: "HEAD" });
        if (!check.ok) brokenLinks.push({ page: path, href });
      }
    }

    const largestImages = await Promise.all(["/assets/tuitionluma-cap-icon.png", "/assets/tuitionluma-icon.png"].map(async path => {
      const response = await fetch(`${this.siteOrigin}${path}`, { method: "HEAD" });
      const size = number(response.headers.get("content-length"));
      return { path, size, sizeLabel: bytes(size) };
    }));

    return {
      largestImages: largestImages.sort((a, b) => b.size - a.size),
      slowestPages: pages.sort((a, b) => b.durationMs - a.durationMs).slice(0, 10).map(page => ({ url: new URL(page.url).pathname, durationMs: page.durationMs })),
      brokenLinks: brokenLinks.slice(0, 20),
      missingMetadata: missingMetadata.slice(0, 20),
      schemaStatus: schemaStatus.slice(0, 20)
    };
  }
}

class ContentOpportunityAnalyzer {
  constructor(performance, searchConsole) {
    this.performance = performance || {};
    this.searchConsole = searchConsole || {};
  }

  build() {
    const nearPageOne = this.searchConsole.nearPageOneQueries || [];
    const topPages = this.searchConsole.topPages || [];
    return {
      pagesNeedingExpansion: topPages.slice(0, 6).map(row => ({
        page: shortPath(row.page),
        reason: "High search visibility page; review whether the editorial section answers the query intent."
      })),
      faqOpportunities: nearPageOne.slice(0, 6).map(row => ({
        topic: row.query,
        reason: "Ranking near page one; add a concise FAQ if the page does not directly answer this query."
      })),
      internalLinks: topPages.slice(0, 6).map(row => ({
        page: shortPath(row.page),
        suggestion: "Add contextual links to one related school, comparison, and program page."
      })),
      suggestedComparisons: nearPageOne.slice(0, 5).map(row => ({
        title: `Comparison page for ${row.query}`,
        reason: "Search demand exists and the query is close to stronger visibility."
      })),
      suggestedHubs: [
        { title: "Public universities by state", reason: "Supports school discovery and state residency intent." },
        { title: "Online college cost guide", reason: "Several generated school pages include online institutions." },
        { title: "Low-debt college paths", reason: "Connects affordability, debt, and repayment planning." }
      ]
    };
  }
}

class AIAdvisor {
  constructor(data, statuses) {
    this.data = data;
    this.statuses = statuses;
  }

  build() {
    const recommendations = [];
    const sc = this.data.searchConsole || {};
    const analytics = this.data.analytics || {};
    const performance = this.data.performance || {};

    if ((sc.nearPageOneQueries || []).length) {
      const query = sc.nearPageOneQueries[0];
      recommendations.push({
        impact: "High",
        title: `Move "${query.query}" closer to page one`,
        detail: `Average position is ${query.position?.toFixed?.(1) || "near page one"}. Add direct answer copy, FAQ coverage, and internal links from related pages.`,
        expectedImpact: "Could improve clicks if the page moves from positions 8-20 into the top results."
      });
    }
    if ((sc.topPages || []).length && (sc.topQueries || []).length) {
      recommendations.push({
        impact: "Medium",
        title: "Strengthen top SEO pages",
        detail: `${shortPath(sc.topPages[0].page)} is already receiving search visibility. Expand it around the strongest related query: "${sc.topQueries[0].query}".`,
        expectedImpact: "Likely improves CTR and long-tail relevance."
      });
    }
    if ((performance.largestImages || []).some(image => image.size > 500000)) {
      recommendations.push({
        impact: "Medium",
        title: "Compress oversized app icon assets",
        detail: "At least one image is larger than 500KB. Add optimized social/app preview variants for faster first load.",
        expectedImpact: "Improves page speed and crawl efficiency."
      });
    }
    if (!analytics.users) {
      recommendations.push({
        impact: "High",
        title: "Connect Google Analytics",
        detail: "GA4 is not returning live website visitor data. Configure the provider to understand acquisition and conversion behavior.",
        expectedImpact: "Unlocks landing page and source-level growth decisions."
      });
    }
    if (!this.statuses.some(status => status.key === "appStore" && status.ok && status.configured)) {
      recommendations.push({
        impact: "High",
        title: "Connect App Store Connect",
        detail: "Downloads, product page views, app units, and review data are needed to connect SEO work to app growth.",
        expectedImpact: "Creates a closed loop between organic traffic and app installs."
      });
    }

    const configured = this.statuses.filter(status => status.configured).length;
    const summary = configured
      ? `Growth intelligence is using ${configured} configured provider${configured === 1 ? "" : "s"}. SEO clicks are ${formatSafe(sc.clicks)}, organic users are ${formatSafe(analytics.organicUsers)}, and ${recommendations.length} prioritized recommendations are ready.`
      : "External providers require configuration. The dashboard is rendering live site-health checks until API credentials are added.";

    return { summary, recommendations };
  }
}

function mapSearchRows(rows = [], dimension) {
  return rows.map(row => ({
    [dimension]: row.keys?.[0],
    clicks: row.clicks || 0,
    impressions: row.impressions || 0,
    ctr: row.ctr || 0,
    position: row.position || 0
  }));
}

function mapAnalyticsRows(rows = [], keyName, metricName) {
  return rows.map(row => ({
    [keyName]: row.dimensionValues?.[0]?.value,
    [metricName]: number(row.metricValues?.[0]?.value)
  }));
}

function metricValue(report, rowIndex, metricIndex) {
  return number(report.rows?.[rowIndex]?.metricValues?.[metricIndex]?.value);
}

function exactFilter(fieldName, value) {
  return {
    filter: {
      fieldName,
      stringFilter: { matchType: "EXACT", value }
    }
  };
}

async function fetchText(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Unable to fetch ${url}`);
  return response.text();
}

async function appStoreJson(path, token) {
  const response = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    headers: { authorization: `Bearer ${token}` }
  });
  const payload = await response.json();
  if (!response.ok) throw new Error(payload.errors?.[0]?.detail || "App Store Connect request failed.");
  return payload;
}

async function appStoreJwt(env) {
  const header = { alg: "ES256", kid: env.APP_STORE_CONNECT_KEY_ID, typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: env.APP_STORE_CONNECT_ISSUER_ID,
    iat: now,
    exp: now + 20 * 60,
    aud: "appstoreconnect-v1"
  };
  const signingInput = `${base64Url(JSON.stringify(header))}.${base64Url(JSON.stringify(payload))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(env.APP_STORE_CONNECT_PRIVATE_KEY),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(signingInput));
  return `${signingInput}.${base64UrlBytes(new Uint8Array(signature))}`;
}

function pemToArrayBuffer(pem) {
  const normalized = pem.replace(/\\n/g, "\n").replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index);
  return bytes.buffer;
}

function base64Url(value) {
  return base64UrlBytes(new TextEncoder().encode(value));
}

function base64UrlBytes(bytes) {
  let binary = "";
  bytes.forEach(byte => binary += String.fromCharCode(byte));
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function parseTsv(text) {
  const lines = text.trim().split(/\r?\n/);
  if (lines.length < 2) return [];
  const headers = lines[0].split("\t");
  return lines.slice(1).map(line => {
    const values = line.split("\t");
    return Object.fromEntries(headers.map((header, index) => [header, values[index]]));
  });
}

function summarizeSentiment(reviews) {
  if (!reviews.length) return "No recent reviews returned.";
  const average = reviews.reduce((sum, review) => sum + (review.rating || 0), 0) / reviews.length;
  if (average >= 4.2) return "Recent reviews skew positive. Watch for repeated feature requests.";
  if (average >= 3.2) return "Recent reviews are mixed. Review themes should be monitored before each release.";
  return "Recent reviews need attention. Prioritize recurring complaints and crash reports.";
}

function bytes(value) {
  if (!value) return "Unknown";
  if (value > 1024 * 1024) return `${(value / (1024 * 1024)).toFixed(1)}MB`;
  return `${Math.round(value / 1024)}KB`;
}

function number(value) {
  if (value === null || value === undefined || value === "") return 0;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function shortPath(url) {
  if (!url) return "Not reported";
  try {
    return new URL(url).pathname;
  } catch {
    return url;
  }
}

function formatSafe(value) {
  if (value === null || value === undefined) return "Configuration Required";
  return new Intl.NumberFormat("en-US").format(value);
}
