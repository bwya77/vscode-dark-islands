{
  description = "Islands Dark Theme for VS Code";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        islandsDarkExtension = pkgs.stdenv.mkDerivation {
          pname = "islands-dark";
          version = "0.0.2";
          src = ./.;

          installPhase = ''
            mkdir -p "$out/share/vscode/extensions/bwya77.islands-dark"
            cp -r package.json themes "$out/share/vscode/extensions/bwya77.islands-dark/"
          '';

          passthru = {
            vscodeExtUniqueId = "bwya77.islands-dark";
            vscodeExtPublisher = "bwya77";
            vscodeExtName = "islands-dark";
          };
        };

        setiFolderExtension = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
          mktplcRef = {
            name = "vscode-theme-seti-folder";
            publisher = "l-igh-t";
            version = "1.3.0";
            sha256 = "0y3bcgsdi3qcy4vj82a3m53dfil95p8qvc50rxdbnii8nxgcjan5";
          };
        };

        bearSansUiFonts = pkgs.stdenv.mkDerivation {
          pname = "bear-sans-ui";
          version = "1.0.0";
          src = ./fonts;
          installPhase = ''
            mkdir -p $out/share/fonts/opentype
            cp *.otf $out/share/fonts/opentype/
          '';
        };

        islandsDarkFonts = pkgs.symlinkJoin {
          name = "islands-dark-fonts";
          paths = [
            bearSansUiFonts
            pkgs.ibm-plex
            (pkgs.nerd-fonts.fira-code or (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; }))
          ];
        };

        settingsJson = builtins.fromJSON (builtins.readFile ./settings.json);

        # Extract the CSS object from settings.json
        customCssObj = settingsJson."custom-ui-style.stylesheet" or {};

        # Convert the JSON object into a valid CSS string
        toCss = obj:
          builtins.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (selector: rules:
              "${selector} {\n" +
              builtins.concatStringsSep "\n" (
                pkgs.lib.mapAttrsToList (prop: value: "  ${prop}: ${value};") rules
              ) +
              "\n}"
            ) obj
          );

        customCssString = toCss customCssObj;

        mkVscode = { vscodePackage ? pkgs.vscode, extraExtensions ? [] }:
          let
            # PATCH AT BUILD TIME: Instead of relying on the extension to modify files at runtime
            # (which fails on a read-only Nix store), we append the CSS directly to VS Code's core
            # CSS file during the build phase.
            patchedVscode = vscodePackage.overrideAttrs (old: {
              postInstall = (old.postInstall or "") + ''
                CSS_FILE=$(find $out/lib -name "workbench.desktop.main.css" | head -n 1)
                if [ -n "$CSS_FILE" ]; then
                  echo "Appending custom CSS to $CSS_FILE"
                  cat ${pkgs.writeText "islands-dark.css" customCssString} >> "$CSS_FILE"
                else
                  echo "Warning: workbench.desktop.main.css not found!"
                fi
              '';
            });

            vscodeWithExts = pkgs.vscode-with-extensions.override {
              vscode = patchedVscode;
              vscodeExtensions = [
                islandsDarkExtension
                setiFolderExtension
              ] ++ extraExtensions;
            };

            configDirName = if vscodePackage.pname == "vscodium" then "VSCodium" else "Code";
            executableName = vscodePackage.meta.mainProgram or (if vscodePackage.pname == "vscodium" then "codium" else "code");

          in pkgs.symlinkJoin {
            name = "islands-dark-${vscodePackage.pname}";
            paths = [ vscodeWithExts ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/${executableName} \
                --run '
                  # Apply settings.json on first run
                  if [ "$(uname)" = "Darwin" ]; then
                    CONFIG_DIR="$HOME/Library/Application Support/${configDirName}/User"
                  else
                    CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/${configDirName}/User"
                  fi

                  mkdir -p "$CONFIG_DIR"
                  FLAG_FILE="$CONFIG_DIR/.islands_dark_first_run"

                  if [ ! -f "$FLAG_FILE" ]; then
                    if [ -f "$CONFIG_DIR/settings.json" ]; then
                      cp "$CONFIG_DIR/settings.json" "$CONFIG_DIR/settings.json.pre-islands-dark"
                    fi
                    rm -f "$CONFIG_DIR/settings.json"
                    cp ${./settings.json} "$CONFIG_DIR/settings.json"
                    chmod 644 "$CONFIG_DIR/settings.json"
                    touch "$FLAG_FILE"
                  fi
                '
            '';
            meta = (vscodePackage.meta or {}) // {
              mainProgram = executableName;
            };
          };

      in
      {
        packages = {
          default = mkVscode { vscodePackage = pkgs.vscode; };
          vscode = mkVscode { vscodePackage = pkgs.vscode; };
          vscodium = mkVscode { vscodePackage = pkgs.vscodium; };

          extension-islands-dark = islandsDarkExtension;
          extension-seti-folder = setiFolderExtension;

          fonts = islandsDarkFonts;
        };

        lib = {
          inherit mkVscode;
          settings = settingsJson;
        };

        overlays.default = final: prev: {
          islands-dark = {
            vscode = mkVscode { vscodePackage = prev.vscode; };
            vscodium = mkVscode { vscodePackage = prev.vscodium; };
            extensions = {
              islands-dark = islandsDarkExtension;
              seti-folder = setiFolderExtension;
            };
            fonts = islandsDarkFonts;
          };
        };
      }
    );
}
