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
  const completion = providers.length ? Math.round((connected / providers.length) * 100) : 0;
  setSettingsStatus("Live", "Provider wizard ready", `${completion}% complete. ${connected}/${providers.length} providers connected.`);
  document.getElementById("settings-grid").innerHTML = `
    <article class="wizard-progress">
      <div>
        <span>${completion}% complete</span>
        <strong>Production intelligence setup</strong>
      </div>
      <div class="progress-track"><div style="width: ${completion}%"></div></div>
    </article>
    ${providers.map((provider, index) => wizardStep(provider, index)).join("")}
  `;
}

function wizardStep(provider, index) {
  const missing = (provider.credentials || []).filter(item => !item.configured);
  const healthIcon = provider.configured ? "🟢" : "🔴";
  return `
    <article class="settings-card wizard-step">
      <div class="step-number">${index + 1}</div>
      <div class="settings-card-header">
        <div>
          <span class="tag ${provider.configured ? "connected-tag" : "required-tag"}">${healthIcon} ${provider.configured ? "Connected" : "Connect"}</span>
          <h3>${escapeHtml(provider.name)}</h3>
          <p>${escapeHtml(provider.statusLabel)} · ${escapeHtml(provider.authentication)}</p>
          <p>Estimated setup time: ${escapeHtml(provider.setupTimeMinutes || 0)} minutes</p>
        </div>
        <a class="connect-button" href="#${escapeHtml(provider.key)}">${provider.configured ? "Review" : "Connect"}</a>
      </div>
      ${provider.autoDetected?.length ? `
        <div class="auto-list">
          <strong>Auto-detected</strong>
          ${provider.autoDetected.map(item => `<p>${escapeHtml(item)}</p>`).join("")}
          ${provider.autoDetectedValues?.siteOrigin ? `<p><strong>Origin:</strong> ${escapeHtml(provider.autoDetectedValues.siteOrigin)}</p>` : ""}
        </div>
      ` : ""}
      <div class="env-list" id="${escapeHtml(provider.key)}">
        ${(provider.credentials || []).map(credential => `
          <div class="env-row">
            <div>
              <span>${escapeHtml(credential.label)}</span>
              <p>${escapeHtml(credential.howToCreate)}</p>
              <p>Expected setup time: ${escapeHtml(credential.setupTimeMinutes || provider.setupTimeMinutes || 5)} minutes</p>
            </div>
            <strong class="${credential.configured ? "env-set" : "env-missing"}">${credential.configured ? "Connected" : "Missing"}</strong>
          </div>
        `).join("") || `<div class="env-row"><div><span>No credentials required</span><p>This provider configures itself from the current request and Cloudflare Pages runtime.</p></div><strong class="env-set">Connected</strong></div>`}
      </div>
      ${missing.length ? `<p class="developer-note">Developer details: missing ${missing.map(item => item.variables.join(", ")).join("; ")}.</p>` : ""}
      <div class="setup-list">
        ${(provider.setup || []).map(item => `<p>${escapeHtml(item)}</p>`).join("")}
      </div>
    </article>
  `;
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
