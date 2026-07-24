// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "controllers"
import "@hotwired/turbo-rails"

const appEnvironment = document.querySelector('meta[name="app-environment"]')?.content

async function removeDevelopmentServiceWorker() {
  const registrations = await navigator.serviceWorker.getRegistrations()
  const appRegistrations = registrations.filter((registration) => {
    return new URL(registration.scope).origin === window.location.origin
  })
  const wasControlled = Boolean(navigator.serviceWorker.controller)

  await Promise.all(appRegistrations.map((registration) => registration.unregister()))

  if ("caches" in window) {
    const cacheNames = await caches.keys()
    await Promise.all(
      cacheNames
        .filter((cacheName) => cacheName.startsWith("onmangequoi-"))
        .map((cacheName) => caches.delete(cacheName))
    )
  }

  if (wasControlled && appRegistrations.length > 0) window.location.reload()
}

if ("serviceWorker" in navigator && window.isSecureContext && appEnvironment === "production") {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker.js", { scope: "/" }).catch((error) => {
      console.warn("Service worker registration failed", error)
    })
  }, { once: true })
} else if ("serviceWorker" in navigator && appEnvironment !== "production") {
  window.addEventListener("load", () => {
    removeDevelopmentServiceWorker().catch((error) => {
      console.warn("Service worker cleanup failed", error)
    })
  }, { once: true })
}
