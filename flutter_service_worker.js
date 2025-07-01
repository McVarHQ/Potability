'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"manifest.json": "b2b6f13cd9d94f55616bafc9d7e27362",
"main.dart.js": "05e8d1c82d602325504f16d2be3074e0",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"index.html": "93a45d538981ff5b99a9b3d4eca8b058",
"/": "93a45d538981ff5b99a9b3d4eca8b058",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/AssetManifest.bin.json": "b16454acf1bbf6fe785d831ddc692c55",
"assets/AssetManifest.bin": "bf05f575ee01a4f318bf22425991b446",
"assets/NOTICES": "7b35596b5ea42902e70c929f6e94b68a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/assets/tds.png": "165266552f3b7011f86cb004873ca7f9",
"assets/assets/error.png": "67d4da553d2f84d643b92a1705434cfc",
"assets/assets/uni_logo_full.png": "1b6a5af950fca3d7d3b9c91fa8572c62",
"assets/assets/danger.png": "6a04fc4766444e1272aa094a47eb88d0",
"assets/assets/danger.svg": "0dc5d56dec151100e80d93f754a84c7c",
"assets/assets/error.svg": "a425793a85bc5ae2144e6f17c8afba8d",
"assets/assets/menu.json": "d8242b020e8871682e768d17ffdc6eee",
"assets/assets/aws/private.key": "f421006d12c2bdbb392cbfb93fd7cd25",
"assets/assets/aws/cert.pem": "8f71faae6e9ea95ed85164039d4f429e",
"assets/assets/aws/CA.pem": "13e973f895b7a047f65bcf16631a4c83",
"assets/assets/temperature.svg": "d6cc711140fbd63a5b23711f8395242b",
"assets/assets/block.png": "47577505d7f39b95b0000442c31fe2de",
"assets/assets/turbidity.png": "4ed13d1ac892e1bc0d2684b1393dadcf",
"assets/assets/do.svg": "f378f07abd04bd80441c2b411ff7cd0c",
"assets/assets/water_drop.png": "d78f342f14cb570c8cec5d77cfd79122",
"assets/assets/ph.png": "21e4e631d68767b17c958d6e9667b362",
"assets/assets/ph.svg": "c8b6f966b0f375a735797881e5436ad1",
"assets/assets/tds.svg": "95276919b5a6c3c06ad1739febfe0688",
"assets/assets/do.png": "ca79d5b29f6b8b26a24d44609a0247dd",
"assets/assets/filter.png": "a7e217c7439376fec3f2a757f1bfef7f",
"assets/assets/block.svg": "814c09d3513ec746d7b80c044775b64c",
"assets/assets/water_full.json": "f27ed92cdfa97319e70eeec433e47fb7",
"assets/assets/clear.png": "92a3ece99d9cd820f92bf0f52e767d55",
"assets/assets/clear.svg": "731c4a3fdd48fffed51b44c49d61562f",
"assets/assets/turbidity.svg": "741fb8c3dfeddeb8615740b9f1f366a1",
"assets/assets/filter.svg": "5b0ffabc8ed888713618d8c3497a2d7f",
"assets/assets/fonts/Saira_Expanded-Medium.ttf": "e1d22c014da6e09517c893a7731ccf7d",
"assets/assets/temperature.png": "de87b4f2e1cbf75c23a3f2d97e108ea4",
"assets/assets/leaf.png": "54ab4f3d0f0e71c26f6b8a6b35f161b7",
"assets/assets/uni_logo.png": "40401fcc05d37034370d84032236989f",
"assets/assets/leaf.svg": "ad9d7c10a77e0514c9c191422c706de9",
"assets/assets/water.json": "ea00968985492e18ab0d04d5977d0768",
"assets/AssetManifest.json": "dbf8f3b8b8b9e64a994d76a7fb8e0e42",
"assets/fonts/MaterialIcons-Regular.otf": "d738196660eb44e82c8e35930df7932f",
"assets/FontManifest.json": "8a65afdb3597d563c8261d4a831b977d",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"flutter_bootstrap.js": "af0c488e3c25a4ef4097bde794e88881",
"version.json": "cca575a4f28042393b3ab6f42de32818"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
