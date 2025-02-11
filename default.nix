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
, target ? "gui"
}:

let
  subPackagesMap = {
    gui = [ "cmd/geteduroam-gui" ];
    cli = [ "cmd/geteduroam-cli" ];
    notifcheck = [ "cmd/geteduroam-notifcheck" ];
  };

  # Only include GUI-specific inputs when building GUI
  guiInputs = with pkgs; [
    gtk4
    libnotify
    libadwaita
  ];

  guiNativeInputs = with pkgs; [
    makeWrapper
    gtk4
    libnotify
    libadwaita
    wrapGAppsHook4
  ];

  # GUI-specific post-install script
  guiPostInstall = ''
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
in
buildGoApplication {
  pname = "geteduroam-${target}";
  version = "0.5";
  pwd = ./.;
  src = ./.;
  modules = ./gomod2nix.toml;
  subPackages = subPackagesMap.${target};

  nativeBuildInputs = if target == "gui" then guiNativeInputs else [];
  buildInputs = if target == "gui" then guiInputs else [];
  postInstall = if target == "gui" then guiPostInstall else "";

  # Create symlink with the correct name if needed
  postFixup = ''
    if [ ! -f "$out/bin/geteduroam-${target}" ]; then
      ln -s "$out/bin/"* "$out/bin/geteduroam-${target}"
    fi
  '';
}
