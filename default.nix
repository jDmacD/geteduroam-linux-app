{ pkgs ? (
    let
      inherit (builtins) fetchTree fromJSON readFile;
      inherit ((fromJSON (readFile ./flake.lock)).nodes) nixpkgs gomod2nix;
    in
    import (fetchTree nixpkgs.locked) {
      overlays = [
        (import "${fetchTree gomod2nix.locked}/overlay.nix")
      ];
    }
  )
, buildGoApplication ? pkgs.buildGoApplication
}:

buildGoApplication {
  pname = "geteduroam";
  version = "0.5";
  pwd = ./.;
  src = ./.;
  modules = ./gomod2nix.toml;
  subPackages = [
    "cmd/geteduroam-cli"
    "cmd/geteduroam-gui"
    "cmd/geteduroam-notifcheck"
  ];

  nativeBuildInputs = with pkgs; [
    makeWrapper

    gtk4
    libnotify
    libadwaita
    wrapGAppsHook4

    # pkg-config
  ];

  buildInputs = with pkgs; [
    gtk4
    libnotify
    libadwaita
  ];


postInstall = ''
  wrapProgram $out/bin/geteduroam-gui \
    --prefix PATH : "${pkgs.pkg-config}/bin"  \
    --prefix PKG_CONFIG_PATH : "${pkgs.cairo.dev}/lib/pkgconfig" \
    --prefix PKG_CONFIG_PATH : "${pkgs.glib.dev}/lib/pkgconfig" \
    --prefix PKG_CONFIG_PATH : "${pkgs.gdk-pixbuf.dev}/lib/pkgconfig" \
    --prefix PKG_CONFIG_PATH : "${pkgs.graphene.dev}/lib/pkgconfig" \
    --prefix PKG_CONFIG_PATH : "${pkgs.pango.dev}/lib/pkgconfig" \
    --prefix PKG_CONFIG_PATH : "${pkgs.harfbuzz.dev}/lib/pkgconfig" \
    --prefix PKG_CONFIG_PATH : "${pkgs.gtk4.dev}/lib/pkgconfig" \
    --prefix PKG_CONFIG_PATH : "${pkgs.vulkan-loader.dev}/lib/pkgconfig" \
    --prefix PKG_CONFIG_PATH : "${pkgs.libadwaita.dev}/lib/pkgconfig" 
'';
}
