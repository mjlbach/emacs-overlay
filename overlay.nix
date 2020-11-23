let packages = (prev.callPackage ./default.nix { });
in {
  inherit (packages) emacsPgtk;
}
