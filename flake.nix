{
  description = "Reusable and extensible Quarto environment builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      # Expose nixpkgs for child flakes to ensure consistent versioning
      # Access as: quarto-base.nixpkgsFor.${system}
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});

      # Access as: quarto-base.lib.${system}.mkQuartoEnv
      lib = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Function that can be used by other flakes to override Quarto's
          # extraPythonPackages
          mkQuartoEnv =
            {
              extraPythonPackages ? (ps: [ ]),
            }:
            pkgs.quarto.override {
              inherit extraPythonPackages;
            };

          # Function that can be used by other flakes to override Quarto's python
          # interpreter and extraPythonPackages to allow overriding python with
          # additional packages that are not in nixpkgs
          mkQuartoCustomPython =
            {
              python ? pkgs.python3,
              extraPythonPackages ? (ps: [ ]),
            }:
            pkgs.quarto.override {
              python3 = python;
              inherit extraPythonPackages;
            };
        }
      );
    };
}
