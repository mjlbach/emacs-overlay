{ inputs, pkgs }:
let
  # gitignore.nix 
  gitignoreSource = (import inputs."gitignore.nix" { inherit (pkgs) lib; }).gitignoreSource;

  pre-commit-hooks = (import inputs."pre-commit-hooks.nix");

  src = gitignoreSource ./..;

  # provided by shell.nix
  devTools = {
    inherit (pre-commit-hooks) pre-commit;
  };

  # to be built by github actions
  ci = {
    pre-commit-check = pre-commit-hooks.run {
      inherit src;
      hooks = {
        shellcheck.enable = true;
        nixpkgs-fmt.enable = true;
        nix-linter.enable = true;
      };
    };
  };
in
pkgs.mkShell {
  buildInputs = builtins.attrValues devTools;
  shellHook = ''
    ${ci.pre-commit-check.shellHook}
  '';
}
