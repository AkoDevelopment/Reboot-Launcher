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
