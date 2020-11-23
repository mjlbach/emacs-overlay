final: prev:
let packages = (prev.callPackage ./default.nix { }).packages;
in {
  inherit (packages) emacsPgtkGcc;
}
