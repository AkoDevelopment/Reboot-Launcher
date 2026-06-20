function updateClock() {
  const now = new Date();
  const hours = now.getHours() % 12 || 12;
  const minutes = String(now.getMinutes()).padStart(2, "0");
  const ampm = now.getHours() >= 12 ? "PM" : "AM";
  const el = document.getElementById("clock-text");
  if (el) el.textContent = `${hours}:${minutes} ${ampm}`;
}

updateClock();
setInterval(updateClock, 1000 * 30);

// Bridges to the native Flutter host (see lib/src/widget/web_app_shell.dart).
function callNative(action, payload) {
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.postMessage({ action, payload });
  } else {
    console.log("[native bridge stub]", action, payload);
  }
}

// Window controls
document.getElementById("minimize-btn")?.addEventListener("click", () => callNative("minimize"));
document.getElementById("close-btn")?.addEventListener("click", () => callNative("close"));

const dragRegion = document.getElementById("drag-region");
dragRegion?.addEventListener("mousedown", (event) => {
  if (event.target.closest(".title-bar-buttons")) return;
  if (event.button !== 0) return;
  callNative("startDrag");
});

// Auth
document.getElementById("login-btn")?.addEventListener("click", () => callNative("login"));
document.getElementById("play-subtitle-login")?.addEventListener("click", (event) => {
  event.preventDefault();
  callNative("login");
});

// Play page actions
document.getElementById("launch-btn")?.addEventListener("click", () => callNative("launchFortnite"));
document.getElementById("remove-btn")?.addEventListener("click", () => callNative("removeBuild"));
document.getElementById("import-btn")?.addEventListener("click", () => callNative("importBuild"));

// Info page actions
document.getElementById("discord-btn")?.addEventListener("click", () => callNative("openDiscord"));
document.getElementById("tutorial-btn")?.addEventListener("click", () => callNative("startTutorial"));
document.getElementById("bug-report-btn")?.addEventListener("click", () => callNative("reportBug"));

// Settings page actions
document.getElementById("language-select")?.addEventListener("change", (event) => callNative("setLanguage", event.target.value));
document.getElementById("theme-select")?.addEventListener("change", (event) => callNative("setTheme", event.target.value));
document.getElementById("install-dir-btn")?.addEventListener("click", () => callNative("openInstallDir"));

// webview_windows relays mouse wheel input to the embedded WebView2 surface
// via a native bridge that doesn't always target the correct scrollable
// element, so scroll the content area manually as a reliable fallback.
const contentArea = document.querySelector(".content");
contentArea?.addEventListener("wheel", (event) => {
  contentArea.scrollTop += event.deltaY;
}, { passive: true });

// Sidebar page navigation
const navIcons = document.querySelectorAll(".nav-icon[data-page]");

function switchToPage(targetPage) {
  navIcons.forEach((icon) => icon.classList.toggle("active", icon.dataset.page === targetPage));

  document.querySelectorAll(".page").forEach((page) => {
    page.hidden = page.id !== `page-${targetPage}`;
  });
}

navIcons.forEach((icon) => {
  icon.addEventListener("click", () => switchToPage(icon.dataset.page));
});

// Matches page -- the match list itself is pushed in from the native side
// (lib/src/widget/web_app_shell.dart calls window.renderMatches via
// executeScript), this file only ever renders whatever it was given. Status,
// player counts etc. are all computed backend-side.
let latestMatches = [];
let currentMatchFilter = "__all__";

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function renderMatchFilters() {
  const container = document.getElementById("match-filters");
  if (!container) return;

  const playlists = new Map();
  latestMatches.forEach((match) => {
    if (!playlists.has(match.playlist)) {
      playlists.set(match.playlist, match.displayName || match.playlist);
    }
  });

  const chips = [`<button class="filter-chip${currentMatchFilter === "__all__" ? " active" : ""}" data-filter="__all__">All Matches</button>`];
  playlists.forEach((displayName, playlist) => {
    const active = currentMatchFilter === playlist ? " active" : "";
    chips.push(`<button class="filter-chip${active}" data-filter="${escapeHtml(playlist)}">${escapeHtml(displayName)}</button>`);
  });

  container.innerHTML = chips.join("");
  container.querySelectorAll(".filter-chip").forEach((chip) => {
    chip.addEventListener("click", () => {
      currentMatchFilter = chip.dataset.filter;
      renderMatchFilters();
      renderMatchList();
    });
  });
}

function formatUptime(seconds) {
  if (seconds === null || seconds === undefined) return "-";
  const minutes = Math.floor(seconds / 60);
  const remaining = seconds % 60;
  return `${minutes}m ${remaining}s`;
}

function buildMatchCard(match) {
  const playerCount = match.maxPlayers ? `${match.playerCount}/${match.maxPlayers}` : `${match.playerCount}`;
  return `
    <div class="match-card" data-server-id="${escapeHtml(match.serverId)}">
      <div class="match-card-main">
        <span class="match-status-dot${match.joinable ? " joinable" : ""}"></span>
        <div class="match-text">
          <span class="match-title">${escapeHtml(match.displayName)} &bull; ${escapeHtml(match.status)}</span>
          <span class="match-subtitle">${escapeHtml(playerCount)} players &bull; Alive: ${escapeHtml(match.aliveCount)}</span>
        </div>
        <div class="match-stats">
          <div class="match-stat">
            <span class="match-stat-value">${escapeHtml(playerCount)}</span>
            <span class="match-stat-label">Players</span>
          </div>
          <div class="match-stat">
            <span class="match-stat-value">${escapeHtml(match.aliveCount)}</span>
            <span class="match-stat-label">Alive</span>
          </div>
        </div>
        <svg class="match-chevron" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
      </div>
      <div class="match-details">
        <div class="match-detail">
          <span class="match-detail-label">Server ID</span>
          <span class="match-detail-value">${escapeHtml(match.serverId)}</span>
        </div>
        <div class="match-detail">
          <span class="match-detail-label">Region</span>
          <span class="match-detail-value">${escapeHtml(match.region)}</span>
        </div>
        <div class="match-detail">
          <span class="match-detail-label">Uptime</span>
          <span class="match-detail-value">${escapeHtml(formatUptime(match.uptimeSeconds))}</span>
        </div>
      </div>
    </div>
  `;
}

function renderMatchList() {
  const list = document.getElementById("match-list");
  const empty = document.getElementById("match-empty");
  if (!list || !empty) return;

  const filtered = currentMatchFilter === "__all__"
      ? latestMatches
      : latestMatches.filter((match) => match.playlist === currentMatchFilter);

  if (filtered.length === 0) {
    list.innerHTML = "";
    empty.hidden = false;
    return;
  }

  empty.hidden = true;
  list.innerHTML = filtered.map(buildMatchCard).join("");
  list.querySelectorAll(".match-card").forEach((card) => {
    card.addEventListener("click", () => card.classList.toggle("expanded"));
  });
}

// Called from lib/src/widget/web_app_shell.dart every time the native
// MatchesController's poll of /api/matches comes back with new data.
window.renderMatches = function (matches) {
  latestMatches = matches || [];
  renderMatchFilters();
  renderMatchList();
};

// User dropdown
const userPill = document.getElementById("user-pill");
const userDropdown = document.getElementById("user-dropdown");

userPill?.addEventListener("click", (event) => {
  event.stopPropagation();
  userDropdown.hidden = !userDropdown.hidden;
});

document.addEventListener("click", () => {
  if (userDropdown && !userDropdown.hidden) userDropdown.hidden = true;
});

document.getElementById("settings-dropdown-btn")?.addEventListener("click", () => {
  switchToPage("settings");
  userDropdown.hidden = true;
});

document.getElementById("logout-dropdown-btn")?.addEventListener("click", () => {
  callNative("logout");
  userDropdown.hidden = true;
});
