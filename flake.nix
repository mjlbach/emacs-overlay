{
  description = "Bleeding edge Emacs overlay";

  inputs."pre-commit-hooks.nix" = { url = "github:cachix/pre-commit-hooks.nix"; flake = false; };
  inputs."gitignore.nix" = { url = "github:hercules-ci/gitignore.nix"; flake = false; };

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  inputs.exwm = { url = "github:ch11ng/exwm"; flake = false; };
  inputs.xelb = { url = "github:ch11ng/xelb"; flake = false; };
  inputs.emacs-git = { url = "github:emacs-mirror/emacs"; flake = false; };
  inputs.emacs-pgtk = { url = "github:masm11/emacs/pgtk"; flake = false; };
  inputs.emacs-pgtk-nativecomp = { url = "github:flatwhatson/emacs/pgtk-nativecomp"; flake = false; };

  inputs.emacs-unstable = {
    type = "github";
    owner = "emacs-mirror";
    repo = "emacs";
    ref = "emacs-27";
    flake = false;
  };

  inputs.emacs-nativecomp = {
    type = "github";
    owner = "emacs-mirror";
    repo = "emacs";
    ref = "feature/native-comp";
    flake = false;
  };

  outputs = { ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          emacs-pkgs = with inputs; pkgs.callPackage ./emacs.nix { inherit exwm xelb emacs-git emacs-unstable emacs-pgtk emacs-nativecomp emacs-pgtk-nativecomp; };
        in
        {
          packages = emacs-pkgs;
          defaultPackage = emacs-pkgs.emacsPgtkGcc;
          devShell = import ./shell.nix { inherit inputs pkgs; };
        }
      ) // {
      overlay = _: prev:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${prev.system};
          emacs-pkgs = with inputs; pkgs.callPackage ./emacs.nix { inherit exwm xelb emacs-git emacs-unstable emacs-pgtk emacs-nativecomp emacs-pgtk-nativecomp; };
        in
        {
          inherit (emacs-pkgs) emacsPgtkGcc emacsGcc;
        };
    };
}
