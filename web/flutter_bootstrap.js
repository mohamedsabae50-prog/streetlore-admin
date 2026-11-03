{{flutter_js}}
{{flutter_build_config}}

_flutter.buildConfig.builds.forEach((build) => {
  if (build.mainJsPath) {
    build.mainJsPath += '?v=2.1.7-10-admin-session';
  }
});

_flutter.loader.load();
