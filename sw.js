const CACHE_VERSION='rssc-v1';
const DISP_VERSION='rssc-d-v1';

const resources=[
  'index.hmtl',
  'Re_Simple_shooting.pde',
  'Bullet.pde',
  'Enemy.pde',
  'Event.pde',
  'Game.pde',
  'GUI.pde',
  'Particle.pde',
  'Strategy.pde',
  'Util.pde',
  './js/processing.min.js',
  './js/wrapper.js',
  './css/app.css',
  './data/font/NotoSansJP-Light.ttf',
  './data/font/NotoSansJP-Thin.ttf',
  './data/image/Attack_mask.png',
  './data/image/Defence_mask.png',
  './data/image/HP_mask.png',
  './data/lang/ja_jp.json',
  './data/save/save_base.json',
  './data/save/save.json',
  './data/skills/Tree.json',
  './data/sound/BulletCancel.wav',
  './data/sound/Damaged.wav',
  './data/sound/Defeat.wav',
  './data/sound/Enter.mp3',
  './data/sound/Exit.wav',
  './data/sound/HitDamaged.wav',
  './data/sound/Impact.wav',
  './data/sound/Shot.wav'
];

for(let i=1;i<7;i++){
  resources.push(`./data/stage/Stage${i}.json`);
}

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then(cache => resources.forEach(r=>{cache.add(r);console.log(`Added ${r}`);}))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        console.log(response);
        return response || fetch(event.request)
          .then(networkResponse => {
            return caches.open(CACHE_VERSION)
              .then(cache => {
                cache.put(event.request, networkResponse.clone());
                return networkResponse;
              });
          });
      })
  );
});

self.addEventListener('activate',(e)=>{
  const cacheWhitelist = [CACHE_VERSION];
  e.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheWhitelist.indexOf(cacheName) === -1) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});