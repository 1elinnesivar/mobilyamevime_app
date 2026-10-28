{{flutter_js}}
{{flutter_build_config}}

// Assets are loaded from /v2/assets/ (rewritten to /assets/ in vercel.json).
// The old /assets/ URLs were served as immutable for a year, so browsers kept
// an icon font without newly added icons. Skipped on localhost for flutter run.
const assetConfig = location.hostname === 'localhost' ? {} : { assetBase: '/v2/' };

_flutter.loader.load({
  config: assetConfig,
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
