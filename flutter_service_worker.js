'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/assets/grits_effects.json": "a2d75d21d4aacf477d0725ebb4c72993",
"assets/assets/sounds/LICENSE.txt": "c4809c66e51533617dd9a7e2c42562c1",
"assets/assets/sounds/explode0.ogg": "65fd51ffb23635efc9fb834093dd8d93",
"assets/assets/sounds/rocket_shoot0.ogg": "d9ae009259cb1cd3f6eb358fd0cc749d",
"assets/assets/sounds/machine_shoot0.ogg": "8200807dd5022cc8f0c073060923de41",
"assets/assets/sounds/shield_activate.ogg": "53f2f58bf290d1788be466e412ed89ac",
"assets/assets/sounds/bg_game.ogg": "c0f394169574c6b7794d606fe9737873",
"assets/assets/sounds/sword_activate.ogg": "19a1b9ac14ace6341cd0530e8e17cf70",
"assets/assets/sounds/bounce0.ogg": "9fe5d4248be018cc6e200fc1f0134030",
"assets/assets/sounds/energy_pickup.ogg": "d60422e645d8e5eba455685fc65e281d",
"assets/assets/sounds/shotgun_shoot0.ogg": "2d18980704612b2b64e3d8fc6c528921",
"assets/assets/sounds/grenade_shoot0.ogg": "5f7bad7869c3adf9a8f032a78522adeb",
"assets/assets/sounds/quad_pickup.ogg": "c96b1e6d7f32102161d17e8ab3b57feb",
"assets/assets/sounds/spawn0.ogg": "4ac6a852f0797e0ae8ba525bc30b9f64",
"assets/assets/sounds/menu_select.ogg": "4f3e5ae097319a92a981c85fc96d4166",
"assets/assets/sounds/bg_menu.ogg": "281c5267c2fd483002dd34dc79599cd7",
"assets/assets/sounds/menu_bump.ogg": "9d8389b6d3370fbb4a2865c429b7dde8",
"assets/assets/sounds/item_pickup0.ogg": "e1243e5db818ccc11ab6bd18f3d43fc7",
"assets/assets/grits_effects.png": "7ece7c43231aad7a8d27de3427dd49be",
"assets/assets/grits_interface.json": "7e296605db30d22d483b97997c385bc6",
"assets/assets/images/grits_master.png": "0f7b020e5ca396fe23322b4587673410",
"assets/assets/tiles/small_map1.tmx": "52c55910a152c9559aabd0c70d2bd219",
"assets/assets/tiles/map1.tmx": "535ae38ee1cec4962cfd67579de5446b",
"assets/assets/Weapons.json": "796fef892305650d9968aa639c059950",
"assets/assets/grits_interface.png": "40744114ea1a3d969dccb5ac1cd5fe4e",
"assets/AssetManifest.json": "01c067a42a1bd25edf19d9171d3fbd90",
"assets/AssetManifest.bin.json": "ed0c458e7080c4fab4b3b80382b89ebf",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "58fe5eb0fa90aa8cee937c09127c36ba",
"assets/AssetManifest.bin": "3fb347965f639f710ca90da7f3379a0e",
"assets/NOTICES": "c3303ff83cb585d44b1fcf61506a2da3",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"manifest.json": "e39040807facd782c7b2ae938ab348b4",
"index.html": "0378ade66d5a059233881db7644ba598",
"/": "0378ade66d5a059233881db7644ba598",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "cb9934cbd5abca358caedaea208ca054",
"main.dart.js": "998683ee76f9336629a80b281cbe8c1c",
"version.json": "a7cc2799090fde4e5bfaf03c79895499",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1"};
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
