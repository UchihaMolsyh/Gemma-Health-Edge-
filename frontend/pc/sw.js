/**
 * Gemma Health Edge - Service Worker for Offline Caching
 * Caches critical resources for true offline experience
 * Version: v6.0
 */

const CACHE_NAME = 'ghe-v9';
const CRITICAL_CACHE = 'ghe-critical-v9';

console.log('[SW] Service Worker v9.0 starting...');

// Only cache files that actually exist in the build
const CRITICAL_URLS = [
  './',
  './index.html',
  './css/styles.css',
  './js/core.js',
  './js/app.js',
  './app-config.json',
];

// Helper: normalize URL by stripping query params
function normalizeUrl(url) {
  const u = new URL(url, self.location.origin);
  return u.origin + u.pathname;
}

// Install event - cache critical resources individually so one failure doesn't abort all
self.addEventListener('install', (event) => {
  console.log('[SW] Installing service worker');
  event.waitUntil(
    caches.open(CRITICAL_CACHE)
      .then(async (cache) => {
        console.log('[SW] Caching critical resources');
        await Promise.all(
          CRITICAL_URLS.map(async (url) => {
            try {
              const req = new Request(url, { cache: 'no-store' });
              const resp = await fetch(req);
              if (resp && resp.status === 200) {
                // Store with normalized URL (no query params)
                const normalizedReq = new Request(normalizeUrl(url));
                await cache.put(normalizedReq, resp.clone());
              } else {
                console.warn('[SW] Skipping cache for', url, 'status', resp.status);
              }
            } catch (e) {
              console.warn('[SW] Failed to cache', url, e.message);
            }
          })
        );
        console.log('[SW] Critical resources cached');
      })
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating service worker');
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== CACHE_NAME && cacheName !== CRITICAL_CACHE) {
              console.log('[SW] Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log('[SW] Service worker activated');
        return self.clients.claim();
      })
  );
});

// No fetch interception — all requests pass through naturally.
// This avoids "message channel closed" errors from respondWith().
// The SW only caches critical files during install for offline use.
