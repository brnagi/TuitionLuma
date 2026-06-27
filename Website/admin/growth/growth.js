const state = {
  token: localStorage.getItem("tuitionlumaGrowthToken") || ""
};

const formatNumber = value => {
  if (value === null || value === undefined || Number.isNaN(Number(value))) return "Not configured";
  return new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 }).format(Number(value));
};

const formatPercent = value => {
  if (value === null || value === undefined || Number.isNaN(Number(value))) return "Not configured";
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
    const headers = state.token ? { "x-admin-token": state.token } : {};
    const response = await fetch("/api/growth", { headers });
    if (response.status === 401) {
      showTokenPanel();
      setStatus("Locked", "Admin token required", "Enter the private token to load growth intelligence.");
      return;
    }
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Dashboard request failed.");
    hideTokenPanel();
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

function showTokenPanel() {
  document.getElementById("token-panel").classList.remove("hidden");
}

function hideTokenPanel() {
  document.getElementById("token-panel").classList.add("hidden");
}

function renderDashboard(data) {
  const updated = data.generatedAt ? new Date(data.generatedAt).toLocaleString() : "just now";
  setStatus("Live", "Growth dashboard ready", `Updated ${updated}. ${data.providerStatus.configured}/${data.providerStatus.total} providers configured.`);
  renderOverview(data);
  renderAdvisor(data.advisor);
  renderSEO(data);
  renderContent(data);
  renderBusiness(data);
  renderPerformance(data);
}

function renderOverview(data) {
  const metrics = [
    ["Downloads today", data.appStore?.downloadsToday, "App Store Connect", "coral"],
    ["Downloads this week", data.appStore?.downloadsThisWeek, "App Store Connect", "coral"],
    ["Organic users", data.analytics?.organicUsers, "Google Analytics", "green"],
    ["Website visitors", data.analytics?.users, "Google Analytics", "blue"],
    ["SEO clicks", data.searchConsole?.clicks, "Search Console", "purple"],
    ["Product page conversion", data.appStore?.productPageConversionRate, "App Store Connect", "green", "percent"],
    ["Current rating", data.reviews?.averageRating, "App reviews", "blue", "position"],
    ["Cache hit rate", data.cloudflare?.cacheHitRate, "Cloudflare", "purple", "percent"]
  ];
  document.getElementById("overview-grid").innerHTML = metrics.map(([label, value, note, tone, type]) => `
    <article class="metric-card" data-tone="${tone}">
      <span>${label}</span>
      <strong>${formatMetric(value, type)}</strong>
      <p>${note}</p>
    </article>
  `).join("");
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
  const cards = [
    tableCard("App Store Connect", [
      { label: "Product page views", value: formatNumber(app.productPageViews) },
      { label: "App units", value: formatNumber(app.appUnits) },
      { label: "Retention", value: formatMetric(app.retentionRate, "percent") }
    ], row => [row.label, row.value]),
    tableCard("Territory breakdown", app.territories, row => [row.territory || row.label, `${formatNumber(row.downloads)} downloads`]),
    tableCard("Recent reviews", reviews.recentReviews, row => [row.title || "Review", `${row.rating || "-"} stars`]),
    tableCard("Future revenue", [
      { label: "Revenue", value: "Placeholder" },
      { label: "MRR", value: "Placeholder" },
      { label: "Subscribers", value: "Placeholder" },
      { label: "Pro conversion", value: "Placeholder" }
    ], row => [row.label, row.value])
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
    return `<article class="data-card"><h3>${title}</h3>${emptyCard("No data yet", "Configure the related provider or wait for enough data to accumulate.")}</article>`;
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

function renderEmptyDashboard(message) {
  document.getElementById("overview-grid").innerHTML = emptyCard("Dashboard could not load", message);
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

document.getElementById("token-form").addEventListener("submit", event => {
  event.preventDefault();
  state.token = document.getElementById("admin-token").value.trim();
  localStorage.setItem("tuitionlumaGrowthToken", state.token);
  loadDashboard();
});

loadDashboard();
