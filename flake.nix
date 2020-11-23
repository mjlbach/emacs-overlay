{
  description = "Bleeding edge Emacs overlay";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.exwm = { url = "github:ch11ng/exwm"; flake = false; };
  inputs.xelb = { url = "github:ch11ng/xelb"; flake = false; };
  inputs.emacs-git = { url = "github:emacs-mirror/emacs"; flake = false; };
  inputs.emacs-unstable = { url = "github:emacs-mirror/emacs"; flake = false; };
  inputs.emacs-pgtk = { url = "github:masm11/emacs/pgtk"; flake = false; };
  inputs.emacs-pgtk-nativecomp = { url = "github:flatwhatson/emacs/pgtk-nativecomp"; flake = false; };

  inputs.emacs-nativecomp = {
    type = "github";
    owner = "emacs-mirror";
    repo = "emacs";
    ref = "feature/native-comp";
    flake = false;
  };

  outputs = { self, flake-utils, exwm, xelb, emacs-git, emacs-unstable, emacs-pgtk, emacs-nativecomp, emacs-pgtk-nativecomp, nixpkgs }:
    (flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      src = pkgs.callPackage ./default.nix { inherit exwm xelb emacs-git emacs-unstable emacs-pgtk emacs-nativecomp emacs-pgtk-nativecomp; };
    in rec {
      inherit (src) packages;
      legacyPackages = packages;
      defaultPackage = packages.emacsGccPgtk packages.emacsGcc;
    }))
    // {
    overlay = final: prev:
      import ./overlay.nix final prev;
    };
}
