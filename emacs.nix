{ pkgs
, exwm
, xelb
, emacs-unstable
, emacs-git
, emacs-nativecomp
, emacs-pgtk
, emacs-pgtk-nativecomp
}:

let
  mkExDrv = emacsPackages: name: args: source:
    emacsPackages.melpaBuild (
      args // {
        pname = name;
        ename = name;
        # version = repoMeta.version;
        version = "28.0.5";
        recipe = builtins.toFile "recipe" ''
          (${name} :fetcher github
          :repo "ch11ng/${name}")
        '';

        src = toString source;
      }
    );

  mkGitEmacs = namePrefix: source:
    builtins.foldl'
      (drv: fn: fn drv)
      pkgs.emacs
      [

        (drv: drv.override { srcRepo = true; })

        (
          drv: drv.overrideAttrs (
            old: {
              # name = "${namePrefix}-${repoMeta.version}";
              name = "${namePrefix}-28.0.5.0";
              # inherit (repoMeta) version;
              version = "28.0.5.0";
              src = toString source;

              patches = [
                ./patches/tramp-detect-wrapped-gvfsd.patch
              ];
              postPatch = old.postPatch + ''
                substituteInPlace lisp/loadup.el \
                --replace '(emacs-repository-get-version)' '"${source.rev}"' \
                --replace '(emacs-repository-get-branch)' '"master"'
              '';
              postInstall = old.postInstall + pkgs.stdenv.lib.optionalString pkgs.stdenv.isDarwin ''
                ln -snf $out/lib/emacs/28.0.50/native-lisp $out/Applications/Emacs.app/Contents/native-lisp
              '';

            }
          )
        )

      ];

  mkPgtkEmacs = namePrefix: jsonFile: (mkGitEmacs namePrefix jsonFile).overrideAttrs (
    old: {
      configureFlags = (pkgs.lib.remove "--with-xft" old.configureFlags)
        ++ pkgs.lib.singleton "--with-pgtk";
    }
  );

  emacsGit = mkGitEmacs "emacs-git" emacs-git;

  emacsGcc = (mkGitEmacs "emacs-gcc" emacs-nativecomp).override {
    nativeComp = true;
  };

  emacsPgtk = mkPgtkEmacs "emacs-pgtk" emacs-pgtk;

  emacsPgtkGcc = (mkPgtkEmacs "emacs-pgtkgcc" emacs-pgtk-nativecomp).override {
    nativeComp = true;
  };

  emacsUnstable = (mkGitEmacs "emacs-unstable" emacs-unstable).overrideAttrs (
    old: {
      patches = [
        ./patches/tramp-detect-wrapped-gvfsd-27.patch
      ];
    }
  );

in
{
  inherit emacsGit emacsUnstable;

  inherit emacsGcc;

  inherit emacsPgtk emacsPgtkGcc;

  emacsGit-nox = (
    (
      emacsGit.override {
        withX = false;
        withGTK2 = false;
        withGTK3 = false;
      }
    ).overrideAttrs (
      oa: {
        name = "${oa.name}-nox";
      }
    )
  );

  emacsUnstable-nox = (
    (
      emacsUnstable.override {
        withX = false;
        withGTK2 = false;
        withGTK3 = false;
      }
    ).overrideAttrs (
      oa: {
        name = "${oa.name}-nox";
      }
    )
  );

  emacsWithPackagesFromUsePackage = import ./elisp.nix { pkgs = pkgs; };

  emacsWithPackagesFromPackageRequires = import ./packreq.nix { pkgs = pkgs; };

  emacsPackagesFor = emacs: (
    (pkgs.emacsPackagesFor emacs).overrideScope' (
      eself: esuper:
        let
          melpaStablePackages = esuper.melpaStablePackages.override {
            archiveJson = ./repos/melpa/recipes-archive-melpa.json;
          };

          melpaPackages = esuper.melpaPackages.override {
            archiveJson = ./repos/melpa/recipes-archive-melpa.json;
          };

          elpaPackages = esuper.elpaPackages.override {
            generated = ./repos/elpa/elpa-generated.nix;
          };

          orgPackages = esuper.orgPackages.override {
            generated = ./repos/org/org-generated.nix;
          };

          epkgs = esuper.override {
            inherit melpaStablePackages melpaPackages elpaPackages orgPackages;
          };

        in
        epkgs // {
          xelb = mkExDrv eself "xelb" {
            packageRequires = [ eself.cl-generic eself.emacs ];
          };

          exwm = mkExDrv eself "exwm" {
            packageRequires = [ eself.xelb ];
          };
        }
    )
  );

}
