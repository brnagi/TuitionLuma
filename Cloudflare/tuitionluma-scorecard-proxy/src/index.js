const SCORECARD_BASE_URL = "https://api.data.gov/ed/collegescorecard/v1/schools";
const CACHE_TTL_SECONDS = 60 * 60 * 24;
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const RATE_LIMIT_MAX_REQUESTS = 90;
const RATE_LIMIT_BUCKETS = new Map();

const ROUTES = new Set(["/schools", "/school", "/programs"]);

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    if (request.method !== "GET") {
      return jsonResponse({ error: "Method not allowed." }, 405);
    }

    const url = new URL(request.url);
    if (!ROUTES.has(url.pathname)) {
      return jsonResponse({ error: "Not found." }, 404);
    }

    const limited = rateLimit(request);
    if (limited) {
      return limited;
    }

    if (!env.COLLEGE_SCORECARD_API_KEY) {
      return jsonResponse({ error: "College data is temporarily unavailable." }, 503);
    }

    const cache = caches.default;
    const cacheKey = new Request(cacheKeyURL(url), request);
    const cached = await cache.match(cacheKey);
    if (cached) {
      return responseWithProxyHeaders(cached, "HIT");
    }

    const upstreamURL = buildUpstreamURL(url, env.COLLEGE_SCORECARD_API_KEY);
    const upstreamResponse = await fetch(upstreamURL, {
      headers: {
        Accept: "application/json",
        "User-Agent": "TuitionLuma College Scorecard Proxy"
      },
      cf: {
        cacheTtl: CACHE_TTL_SECONDS,
        cacheEverything: true
      }
    });

    const response = new Response(upstreamResponse.body, upstreamResponse);
    response.headers.delete("set-cookie");
    response.headers.set("Cache-Control", `public, max-age=${CACHE_TTL_SECONDS}`);

    if (upstreamResponse.ok) {
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
    }

    return responseWithProxyHeaders(response, "MISS");
  }
};

function buildUpstreamURL(requestURL, apiKey) {
  const upstreamURL = new URL(SCORECARD_BASE_URL);

  for (const [key, value] of requestURL.searchParams.entries()) {
    if (key.toLowerCase() !== "api_key") {
      upstreamURL.searchParams.append(key, value);
    }
  }

  upstreamURL.searchParams.set("api_key", apiKey);
  return upstreamURL.toString();
}

function cacheKeyURL(requestURL) {
  const keyURL = new URL(requestURL);
  keyURL.searchParams.delete("api_key");
  keyURL.searchParams.sort();
  return keyURL.toString();
}

function rateLimit(request) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const now = Date.now();
  const bucket = RATE_LIMIT_BUCKETS.get(clientIP);

  if (!bucket || now > bucket.resetAt) {
    RATE_LIMIT_BUCKETS.set(clientIP, {
      count: 1,
      resetAt: now + RATE_LIMIT_WINDOW_MS
    });
    cleanupRateLimitBuckets(now);
    return null;
  }

  bucket.count += 1;
  if (bucket.count <= RATE_LIMIT_MAX_REQUESTS) {
    return null;
  }

  return jsonResponse(
    { error: "Too many requests. Please wait a moment and try again." },
    429,
    { "Retry-After": String(Math.ceil((bucket.resetAt - now) / 1000)) }
  );
}

function cleanupRateLimitBuckets(now) {
  if (RATE_LIMIT_BUCKETS.size < 1000) {
    return;
  }

  for (const [key, bucket] of RATE_LIMIT_BUCKETS.entries()) {
    if (now > bucket.resetAt) {
      RATE_LIMIT_BUCKETS.delete(key);
    }
  }
}

function responseWithProxyHeaders(response, cacheStatus) {
  const headers = new Headers(response.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  headers.set("Access-Control-Allow-Headers", "Content-Type");
  headers.set("X-TuitionLuma-Cache", cacheStatus);

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers
  });
}

function jsonResponse(body, status, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders(),
      ...extraHeaders,
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store"
    }
  });
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
  };
}
