async function loadSettings() {
  setSettingsStatus("Loading", "Checking environment", "Reading Cloudflare Pages environment binding status.");
  try {
    const response = await fetch("/api/growth-settings");
    if (response.status === 401) {
      setSettingsStatus("Locked", "Login required", "Refresh and enter the Growth dashboard username and password.");
      return;
    }
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Settings request failed.");
    renderSettings(data.providers || []);
  } catch (error) {
    setSettingsStatus("Error", "Settings unavailable", error.message);
    document.getElementById("settings-grid").innerHTML = emptyCard("Settings could not load", error.message);
  }
}

function setSettingsStatus(label, title, description) {
  const status = document.getElementById("settings-status");
  status.innerHTML = `<span>${label}</span><strong>${title}</strong><p>${description}</p>`;
}

function renderSettings(providers) {
  const connected = providers.filter(provider => provider.configured).length;
  setSettingsStatus("Live", "Environment checked", `${connected}/${providers.length} providers connected.`);
  document.getElementById("settings-grid").innerHTML = providers.map(provider => `
    <article class="settings-card">
      <div class="settings-card-header">
        <div>
          <span class="tag ${provider.configured ? "connected-tag" : "required-tag"}">${provider.configured ? "Connected" : "Configuration Required"}</span>
          <h3>${escapeHtml(provider.name)}</h3>
          <p>${escapeHtml(provider.statusLabel)} · ${escapeHtml(provider.authentication)}</p>
        </div>
        <strong>${escapeHtml(provider.refreshIntervalMinutes)} min</strong>
      </div>
      <div class="env-list">
        ${(provider.variables || []).map(variable => `
          <div class="env-row">
            <span>${escapeHtml(variable.name)}</span>
            <strong class="${variable.configured ? "env-set" : "env-missing"}">${variable.configured ? "Set" : "Missing"}</strong>
          </div>
        `).join("")}
      </div>
      <div class="setup-list">
        ${(provider.setup || []).map(item => `<p>${escapeHtml(item)}</p>`).join("")}
      </div>
    </article>
  `).join("");
}

function emptyCard(title, description) {
  return `<article class="empty-card"><strong>${escapeHtml(title)}</strong><p>${escapeHtml(description)}</p></article>`;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

loadSettings();
