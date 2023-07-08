{
  inputs = {
    arduino-indexes.url = "github:bouk/arduino-indexes";
    arduino-indexes.flake = false;
    arduino-nix.url = "github:bouk/arduino-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    arduino-indexes,
    arduino-nix,
    flake-utils,
    nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          arduino-nix.overlay
          (arduino-nix.mkArduinoPackageOverlay (arduino-indexes + "/index/package_index.json"))
          (arduino-nix.mkArduinoPackageOverlay (arduino-indexes + "/index/package_keyboardio_index.json"))
        ];
      };
    in rec {
      defaultPackage = pkgs.stdenvNoCC.mkDerivation {
        name = "kbd";
        src = ./.;
        nativeBuildInputs = [packages.arduino-cli pkgs.python3Minimal];
        buildPhase = ''
          for sketch in Model100; do
            arduino-cli compile --output-dir output/$sketch $sketch
            arduino-cli compile --show-properties=unexpanded $sketch | python3 ${./make_flash_script.py} $sketch
          done
        '';
        installPhase = ''
          mv output $out
        '';
        dontPatchShebangs = true;
        meta.license = pkgs.lib.licenses.gpl3Only;
      };

      formatter = pkgs.alejandra;
      packages.arduino-cli = pkgs.wrapArduinoCLI {
        packages = with pkgs.arduinoPackages; [
          platforms.arduino.avr."1.8.6"
          platforms.keyboardio.avr."1.99.8"
          platforms.keyboardio.gd32."1.99.8"
        ];
      };
      packages.clang-format = pkgs.clang-tools.overrideAttrs (final: prev: {
        meta.mainProgram = "clang-format";
      });
    });
}
