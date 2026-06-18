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

document.getElementById("minimize-btn")?.addEventListener("click", () => callNative("minimize"));
document.getElementById("close-btn")?.addEventListener("click", () => callNative("close"));

document.getElementById("launch-btn")?.addEventListener("click", () => callNative("launchFortnite"));
document.getElementById("remove-btn")?.addEventListener("click", () => callNative("removeBuild"));
document.getElementById("import-btn")?.addEventListener("click", () => callNative("importBuild"));
