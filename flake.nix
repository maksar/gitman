{
  description = "Gitman Flake";

  inputs = {
    nixpkgs = {
      url = github:NixOS/nixpkgs/release-20.09;
    };

    bundix = {
      url = github:maksar/bundix;
      flake = false;
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, bundix }:
    flake-utils.lib.eachDefaultSystem
      (system:
        with nixpkgs.legacyPackages.${system};
        let
          ruby = ruby_2_7;

          bundler = bundlerEnv {
            name = "gitman-bundle";
            gemdir = ./.;
            inherit ruby;
          };

          gemDerivations = builtins.attrValues bundler.gems;
          gemConfigs = builtins.filter (v: v != null) (
            builtins.map
              (d:
                if builtins.hasAttr "buildFlags" d.drvAttrs
                then { "${d.gemName}" = d.drvAttrs.buildFlags; }
                else null)
              gemDerivations);
          gemDefinitions = pkgs.lib.mapAttrs (n: v: pkgs.lib.flatten v) (pkgs.lib.zipAttrs gemConfigs);
          shellHook = builtins.concatStringsSep "\n" (
            builtins.attrValues (pkgs.lib.mapAttrs
              (n: v: "export BUNDLE_BUILD__${pkgs.lib.replaceChars [ "-" ] [ "_" ] (pkgs.lib.toUpper n)}=\"${builtins.concatStringsSep " " v}\"")
              gemDefinitions));
        in
        rec {
          defaultApp = {
            type = "app";
            program = "${defaultPackage}/bin/gitman";
          };

          defaultPackage = stdenv.mkDerivation {
            pname = "gitman";
            version = "0.2";
            src = ./.;

            propagatedBuildInputs = [
              bundler
            ];

            doCheck = true;

            checkPhase = ''
              pushd src
              GITMAN_CONFIG_FOLDER=$TMPDIR GITMAN_BITBUCKET_URL= RAILS_ENV=test ${bundler}/bin/rspec
              ${bundler}/bin/rubocop --cache false
              popd
            '';

            installPhase = ''
              mkdir -p $out/bin
              mkdir -p $out/share/gitman
              cp -r src/* $out/share/gitman/
              rm -rf $out/share/gitman/spec


              bin=$out/bin/gitman
              cat > $bin <<EOF
                #!/bin/bash -e
                exec ${bundler}/bin/bundle exec ${ruby}/bin/ruby $out/share/gitman/server.rb \$@
              EOF
              chmod +x $bin
            '';
          };

          devShell = pkgs.mkShell {
            buildInputs = [
              ruby
              bundix
              bundler
            ] ++ map (v: v.outPath) (lib.attrValues self.inputs);

            shellHook = shellHook;
          };
        }
      );
}
