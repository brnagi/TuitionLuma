const formatNumber = value => {
  if (value === null || value === undefined || Number.isNaN(Number(value))) return "Connect";
  return new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 }).format(Number(value));
};

const formatPercent = value => {
  if (value === null || value === undefined || Number.isNaN(Number(value))) return "Connect";
  return `${(Number(value) * 100).toFixed(1)}%`;
};

const formatMetric = (value, type = "number") => {
  if (type === "percent") return formatPercent(value);
  if (type === "position" && value !== null && value !== undefined) return Number(value).toFixed(1);
  return formatNumber(value);
};

async function loadDashboard() {
  setStatus("Loading", "Connecting providers", "Fetching live metrics and site health signals.");
  try {
    const response = await fetch("/api/growth");
    if (response.status === 401) {
      setStatus("Locked", "Login required", "Refresh and enter the Growth dashboard username and password.");
      return;
    }
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Dashboard request failed.");
    renderDashboard(data);
  } catch (error) {
    setStatus("Error", "Dashboard unavailable", error.message);
    renderEmptyDashboard(error.message);
  }
}

function setStatus(label, title, description) {
  const status = document.getElementById("refresh-status");
  status.innerHTML = `<span>${label}</span><strong>${title}</strong><p>${description}</p>`;
}

function renderDashboard(data) {
  const updated = data.generatedAt ? new Date(data.generatedAt).toLocaleString() : "just now";
  const connected = (data.providerStatus.providers || []).filter(provider => provider.status === "Connected").length;
  setStatus("Live", "Growth dashboard ready", `Updated ${updated}. ${connected}/${data.providerStatus.total} providers connected.`);
  renderProviderStatus(data.providerStatus.providers || []);
  renderOverview(data);
  renderAdvisor(data.advisor);
  renderSEO(data);
  renderContent(data);
  renderBusiness(data);
  renderPerformance(data);
}

function renderOverview(data) {
  const providerStatus = providerMap(data);
  const metrics = [
    ["Downloads today", data.appStore?.downloadsToday, "App Store Connect", "coral", "number", "appStore"],
    ["Downloads this week", data.appStore?.downloadsThisWeek, "App Store Connect", "coral", "number", "appStore"],
    ["Organic users", data.analytics?.organicUsers, "Google Analytics", "green", "number", "analytics"],
    ["Website visitors", data.analytics?.users, "Google Analytics", "blue", "number", "analytics"],
    ["SEO clicks", data.searchConsole?.clicks, "Search Console", "purple", "number", "searchConsole"],
    ["Product page conversion", data.appStore?.productPageConversionRate, "App Store Connect", "green", "percent", "appStore"],
    ["Current rating", data.reviews?.averageRating, "App reviews", "blue", "position", "reviews"],
    ["Cache hit rate", data.cloudflare?.cacheHitRate, "Cloudflare", "purple", "percent", "cloudflare"]
  ].filter(([, value,,,, providerKey]) => hasValue(value) || providerStatus[providerKey]?.status === "Connected");

  const cards = metrics.map(([label, value, note, tone, type]) => `
    <article class="metric-card" data-tone="${tone}">
      <span>${label}</span>
      <strong>${formatMetric(value, type)}</strong>
      <p>${note}</p>
    </article>
  `);

  if (!metrics.length) {
    cards.push(connectPromptCard("Connect production providers", "Connect Search Console, Analytics, and App Store Connect to unlock the full growth pulse.", "Open settings", "/admin/settings/"));
  }

  document.getElementById("overview-grid").innerHTML = cards.join("");
}

function renderProviderStatus(providers) {
  document.getElementById("provider-status-panel").innerHTML = providers.map(provider => {
    const connected = provider.status === "Connected";
    const refresh = provider.lastSuccessfulRefresh
      ? new Date(provider.lastSuccessfulRefresh).toLocaleString()
      : "Awaiting first successful refresh";
    const label = connected ? "Connected" : "Connect";
    const healthIcon = connected ? "🟢" : provider.status === "Connection Error" ? "🔴" : "🟡";
    return `
      <article class="provider-card ${connected ? "connected" : "required"}">
        <div>
          <span class="tag ${connected ? "connected-tag" : "required-tag"}">${healthIcon} ${escapeHtml(label)}</span>
          <h3>${escapeHtml(provider.name)}</h3>
          <p>${escapeHtml(provider.connectDescription || "Production provider")}</p>
        </div>
        <p><strong>Last successful sync:</strong> ${escapeHtml(refresh)}</p>
        <p><strong>Last API response:</strong> ${escapeHtml(provider.lastApiResponse || "Not connected")}</p>
        ${connected ? "" : `<a class="connect-button" href="/admin/settings/">Connect · ${escapeHtml(provider.setupTimeMinutes || 10)} min</a>`}
      </article>
    `;
  }).join("");
}

function renderAdvisor(advisor = {}) {
  document.getElementById("advisor-summary").textContent = advisor.summary || "No live recommendations yet. Configure providers to generate a richer executive summary.";
  const recommendations = advisor.recommendations || [];
  document.getElementById("advisor-recommendations").innerHTML = recommendations.length ? recommendations.map(item => `
    <article class="recommendation-card">
      <span class="tag impact-${item.impact.toLowerCase()}">${item.impact} Impact</span>
      <h3>${item.title}</h3>
      <p>${item.detail}</p>
      <p><strong>Expected impact:</strong> ${item.expectedImpact || "Monitor after implementation."}</p>
    </article>
  `).join("") : emptyCard("No AI recommendations", "Recommendations appear when live provider data is available.");
}

function renderSEO(data) {
  const sc = data.searchConsole || {};
  if (!hasRows(sc.topPages) && !hasRows(sc.topQueries)) {
    document.getElementById("seo-panel").innerHTML = connectPromptCard("Connect Google Search Console to unlock search insights.", "See organic clicks, impressions, CTR, keyword rankings, and pages ranking positions 8-20.", "Connect Search Console", "/admin/settings/");
    return;
  }
  const cards = [
    tableCard("Top pages", sc.topPages, row => [row.page || row.label, `${formatNumber(row.clicks)} clicks`]),
    tableCard("Top queries", sc.topQueries, row => [row.query || row.label, `${formatNumber(row.impressions)} impressions`]),
    tableCard("Positions 8-20", sc.nearPageOneQueries, row => [row.query || row.label, `Position ${formatMetric(row.position, "position")}`]),
    tableCard("Fastest growing pages", sc.fastestGrowingPages, row => [row.page || row.label, `+${formatNumber(row.deltaClicks)} clicks`])
  ];
  document.getElementById("seo-panel").innerHTML = cards.join("");
}

function renderContent(data) {
  const content = data.content || {};
  const cards = [
    tableCard("Pages needing expansion", content.pagesNeedingExpansion, row => [row.page, row.reason]),
    tableCard("Missing FAQ opportunities", content.faqOpportunities, row => [row.topic, row.reason]),
    tableCard("Internal linking opportunities", content.internalLinks, row => [row.page, row.suggestion]),
    tableCard("Suggested comparison pages", content.suggestedComparisons, row => [row.title, row.reason]),
    tableCard("Suggested hub pages", content.suggestedHubs, row => [row.title, row.reason])
  ];
  document.getElementById("content-panel").innerHTML = cards.join("");
}

function renderBusiness(data) {
  const app = data.appStore || {};
  const reviews = data.reviews || {};
  if (!hasRows(app.territories) && !hasRows(reviews.recentReviews) && !hasValue(app.appUnits)) {
    document.getElementById("business-panel").innerHTML = connectPromptCard("Connect App Store Connect to begin tracking downloads.", "See downloads, app units, territories, version adoption, reviews, and App Store performance.", "Connect App Store", "/admin/settings/");
    return;
  }
  const cards = [
    tableCard("App Store Connect", [
      { label: "Product page views", value: formatNumber(app.productPageViews) },
      { label: "App units", value: formatNumber(app.appUnits) },
      { label: "Retention", value: formatMetric(app.retentionRate, "percent") }
    ], row => [row.label, row.value]),
    tableCard("Territory breakdown", app.territories, row => [row.territory || row.label, `${formatNumber(row.downloads)} downloads`]),
    tableCard("Recent reviews", reviews.recentReviews, row => [row.title || "Review", `${row.rating || "-"} stars`]),
    connectPromptCard("Revenue tracking is future-ready", "Revenue, MRR, subscribers, and Pro conversion can be added when a revenue provider is configured.", "Review settings", "/admin/settings/")
  ];
  document.getElementById("business-panel").innerHTML = cards.join("");
}

function renderPerformance(data) {
  const performance = data.performance || {};
  const cards = [
    tableCard("Largest images", performance.largestImages, row => [row.path, row.sizeLabel]),
    tableCard("Slowest pages", performance.slowestPages, row => [row.url, `${row.durationMs}ms`]),
    tableCard("Broken links", performance.brokenLinks, row => [row.page, row.href]),
    tableCard("Missing metadata", performance.missingMetadata, row => [row.page, row.field]),
    tableCard("Schema validation", performance.schemaStatus, row => [row.page, row.status])
  ];
  document.getElementById("performance-panel").innerHTML = cards.join("");
}

function tableCard(title, rows = [], mapper) {
  if (!rows || !rows.length) {
    return "";
  }
  return `<article class="data-card"><h3>${title}</h3><div class="table-list">${
    rows.slice(0, 8).map(row => {
      const [left, right] = mapper(row);
      return `<div class="table-row"><span>${escapeHtml(left || "Not reported")}</span><strong>${escapeHtml(right || "")}</strong></div>`;
    }).join("")
  }</div></article>`;
}

function emptyCard(title, description) {
  return `<article class="empty-card"><strong>${title}</strong><p>${description}</p></article>`;
}

function connectPromptCard(title, description, action, href) {
  return `<article class="connect-card">
    <strong>${escapeHtml(title)}</strong>
    <p>${escapeHtml(description)}</p>
    <a class="connect-button" href="${escapeHtml(href)}">${escapeHtml(action)}</a>
  </article>`;
}

function providerMap(data) {
  return Object.fromEntries((data.providerStatus?.providers || []).map(provider => [provider.key, provider]));
}

function hasValue(value) {
  return value !== null && value !== undefined && !Number.isNaN(Number(value));
}

function hasRows(rows) {
  return Array.isArray(rows) && rows.length > 0;
}

function renderEmptyDashboard(message) {
  document.getElementById("overview-grid").innerHTML = emptyCard("Dashboard could not load", message);
  document.getElementById("provider-status-panel").innerHTML = emptyCard("Provider status unavailable", message);
  document.getElementById("advisor-summary").textContent = "No executive summary available.";
  document.getElementById("advisor-recommendations").innerHTML = "";
  ["seo-panel", "content-panel", "business-panel", "performance-panel"].forEach(id => {
    document.getElementById(id).innerHTML = emptyCard("No data", "Resolve the dashboard error and refresh.");
  });
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

loadDashboard();
