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

// These hooks call into the native host app once wired up (e.g. via
// webview_windows' executeScript bridge or window.chrome.webview).
// They're no-ops in a plain browser preview.
function callNative(action, payload) {
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.postMessage({ action, payload });
  } else {
    console.log("[native bridge stub]", action, payload);
  }
}

document.getElementById("minimize-btn")?.addEventListener("click", () => callNative("minimize"));
document.getElementById("maximize-btn")?.addEventListener("click", () => callNative("maximize"));
document.getElementById("close-btn")?.addEventListener("click", () => callNative("close"));

document.querySelector(".btn-primary")?.addEventListener("click", () => callNative("launchFortnite"));
document.querySelector(".btn-secondary")?.addEventListener("click", () => callNative("importBuild"));
document.querySelector(".btn-icon.danger")?.addEventListener("click", () => callNative("removeBuild"));
