{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  otfcc,
  cacert,
  ...
}:
let
  src = fetchFromGitHub {
    owner = "be5invis";
    repo = "Iosevka";
    tag = "v2.2.1";
    hash = "sha256-RkS7g/N/OfcaV5UQJCihLp9UEaiG5F9iZPsVoNHQHGo=";
  };

  # npm dependencies are fetched/built once in a fixed-output derivation.
  # This is needed because Iosevka 2.2.1 has no package-lock.json upstream.
  deps = stdenv.mkDerivation {
    pname = "iosevka-2.2.1-node-modules";
    version = "1";

    inherit src;

    nativeBuildInputs = [
      nodejs
      cacert
    ];
    dontFixup = true;

    postPatch = ''
      cp ${../assets/fonts/iosevka-minimal/package-lock.json} package-lock.json
      substituteInPlace package.json \
        --replace-fail '"verda": "^1.0.0-0"' '"verda": "^1.0.0-3"'
    '';

    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR
      export NIX_SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
      npm ci --ignore-scripts --no-audit --no-fund
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r node_modules $out
      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-LeKhPKrtRF/kpjNxd/+OWWdpbA0Nqft9x4qIYT9MSv8=";
  };
in
stdenv.mkDerivation {
  pname = "iosevka-minimal";
  version = "2.2.1";

  inherit src;

  nativeBuildInputs = [
    nodejs
    otfcc
  ];

  configurePhase = ''
        runHook preConfigure

        cp -r ${deps} node_modules
        sed -i 's/^width = 500/width = 550/' parameters.toml

        cat > private-build-plans.toml <<'TOML'
    [buildPlans.iosevka-minimal]
    family = "Iosevka Minimal"
    design = ["v-a-singlestorey", "v-g-singlestorey", "v-y-curly", "v-one-serifed", "v-q-straight", "v-at-fourfold", "v-numbersign-slanted", "v-percent-dots", "v-brace-straight", "v-i-serifed", "v-l-serifed", "v-f-straight"]

    [buildPlans.iosevka-minimal.weights.regular]
    shape = 400
    menu = 400
    css = 400

    [buildPlans.iosevka-minimal.weights.medium]
    shape = 500
    menu = 500
    css = 500

    [buildPlans.iosevka-minimal.weights.semibold]
    shape = 600
    menu = 600
    css = 600

    [buildPlans.iosevka-minimal.weights.bold]
    shape = 700
    menu = 700
    css = 700

    [buildPlans.iosevka-minimal.weights.extrabold]
    shape = 800
    menu = 800
    css = 800

    [buildPlans.iosevka-minimal.weights.heavy]
    shape = 900
    menu = 900
    css = 900

    [buildPlans.iosevka-minimal.slants]
    upright = "normal"
    italic = "italic"
    oblique = "oblique"
    TOML

        runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    node node_modules/verda/bin/verda -f verdafile.js ttf-unhinted::iosevka-minimal
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -d "$out/share/fonts/truetype/iosevka-minimal"

    # Only the styles Minimal actually shipped.
    install -m644 \
      dist/iosevka-minimal/ttf-unhinted/iosevka-minimal-regular.ttf \
      dist/iosevka-minimal/ttf-unhinted/iosevka-minimal-medium.ttf \
      dist/iosevka-minimal/ttf-unhinted/iosevka-minimal-semibold.ttf \
      dist/iosevka-minimal/ttf-unhinted/iosevka-minimal-bold.ttf \
      dist/iosevka-minimal/ttf-unhinted/iosevka-minimal-extrabold.ttf \
      dist/iosevka-minimal/ttf-unhinted/iosevka-minimal-heavy.ttf \
      dist/iosevka-minimal/ttf-unhinted/iosevka-minimal-mediumitalic.ttf \
      dist/iosevka-minimal/ttf-unhinted/iosevka-minimal-mediumoblique.ttf \
      "$out/share/fonts/truetype/iosevka-minimal/"

    runHook postInstall
  '';

  meta = {
    description = "Iosevka Minimal, a custom build of Iosevka 2.2.1";
    homepage = "https://github.com/gersonfaneto/Magi";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
