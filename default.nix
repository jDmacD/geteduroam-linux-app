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
  version = "0.1";
  pwd = ./.;
  src = ./.;
  modules = ./gomod2nix.toml;

  nativeBuildInputs = with pkgs; [
    pkg-config
    makeWrapper
  ];

  buildInputs = with pkgs; [
    gtk4
    libadwaita
    libnotify
    cairo
    glib
    pango
    gdk-pixbuf
    graphene
  ];

  postInstall = let
    # Create explicit references to the shared libraries
    libPaths = {
      cairo = "${pkgs.cairo}/lib/libcairo.so";
      glib = "${pkgs.glib}/lib/libglib-2.0.so";
      gobject = "${pkgs.glib}/lib/libgobject-2.0.so";
      gtk = "${pkgs.gtk4}/lib/libgtk-4.so";
      pango = "${pkgs.pango}/lib/libpango-1.0.so";
      gdk_pixbuf = "${pkgs.gdk-pixbuf}/lib/libgdk_pixbuf-2.0.so";
    };
  in ''
    wrapProgram $out/bin/geteduroam-gui \
      --prefix PATH : "${pkgs.pkg-config}/bin" \
      --prefix PKG_CONFIG_PATH : "${pkgs.glib.dev}/lib/pkgconfig" \
      --prefix PKG_CONFIG_PATH : "${pkgs.cairo.dev}/lib/pkgconfig" \
      --prefix PKG_CONFIG_PATH : "${pkgs.gtk4.dev}/lib/pkgconfig" \
      --prefix PKG_CONFIG_PATH : "${pkgs.pango.dev}/lib/pkgconfig" \
      --prefix PKG_CONFIG_PATH : "${pkgs.gdk-pixbuf.dev}/lib/pkgconfig" \
      --prefix PKG_CONFIG_PATH : "${pkgs.graphene.dev}/lib/pkgconfig" \
      --prefix PKG_CONFIG_PATH : "${pkgs.libadwaita.dev}/lib/pkgconfig" \
      --prefix GI_TYPELIB_PATH : "${pkgs.gtk4}/lib/girepository-1.0" \
      --prefix GI_TYPELIB_PATH : "${pkgs.libadwaita}/lib/girepository-1.0" \
      --prefix GI_TYPELIB_PATH : "${pkgs.cairo}/lib/girepository-1.0" \
      --prefix GI_TYPELIB_PATH : "${pkgs.glib}/lib/girepository-1.0" \
      --prefix GI_TYPELIB_PATH : "${pkgs.pango}/lib/girepository-1.0" \
      --prefix GI_TYPELIB_PATH : "${pkgs.gdk-pixbuf}/lib/girepository-1.0" \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [
        pkgs.cairo
        pkgs.glib
        pkgs.pango
        pkgs.gtk4
        pkgs.libadwaita
        pkgs.gdk-pixbuf
        pkgs.graphene
      ]}" \
      --set PUREGOTK_CAIRO_PATH "${libPaths.cairo}" \
      --set PUREGOTK_GLIB_PATH "${libPaths.glib}" \
      --set PUREGOTK_GOBJECT_PATH "${libPaths.gobject}" \
      --set PUREGOTK_GTK_PATH "${libPaths.gtk}" \
      --set PUREGOTK_PANGO_PATH "${libPaths.pango}" \
      --set PUREGOTK_GDK_PIXBUF_PATH "${libPaths.gdk_pixbuf}"

    wrapProgram $out/bin/geteduroam-notifcheck \
      --prefix GI_TYPELIB_PATH : "${pkgs.libnotify}/lib/girepository-1.0" \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [
        pkgs.libnotify
      ]}"
  '';
}
