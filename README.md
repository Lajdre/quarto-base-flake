# Shared nixpkgs and Quarto versions for blog posts

I use this flake so new blog posts reuse a pinned nixpkgs revision and its Quarto
version instead of resolving the latest nixpkgs for each new environment.

Each post can add its own Python packages or custom interpreter. Nix reuses the
same nixpkgs source and unchanged package builds in the store. Custom Python
environments and Quarto wrappers can have separate store paths.

## Usage

Each post that needs its own environment has a `flake.nix`. This example gives Quarto
a Python environment with NumPy:

```nix
{
  inputs = {
    quarto-base.url = "github:lajdre/quarto-base-flake";
    nixpkgs.follows = "quarto-base/nixpkgs";
  };

  outputs =
    { nixpkgs, quarto-base, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = quarto-base.nixpkgsFor.${system};

          extendedQuarto = quarto-base.lib.${system}.mkQuartoEnv {
            extraPythonPackages = ps: with ps; [ numpy ];
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              extendedQuarto
            ];
          };
        }
      );
    };
}
```

To select a specific Python version, replace the `extendedQuarto` definition in the
`let` block with something like this:

```nix
python = pkgs.python314;

extendedQuarto = quarto-base.lib.${system}.mkQuartoCustomPython {
  inherit python;
  extraPythonPackages = ps: with ps; [ numpy ];
};
```

The `python` argument defaults to `pkgs.python3`. Both helpers accept an
`extraPythonPackages` function.

For the blog's top-level shell, use `packages = [ pkgs.quarto ];` if you only need
Quarto for `quarto preview` and `quarto publish`.


## Outputs

- `nixpkgsFor.${system}` provides the base flake's nixpkgs package set.
- `lib.${system}.mkQuartoEnv` configures Quarto with additional Python packages.
- `lib.${system}.mkQuartoCustomPython` configures Quarto with a custom Python
  interpreter and optional additional Python packages.

To test a local checkout without changing the project's lock file:

```sh
nix develop --override-input quarto-base path:/absolute/path/to/quarto-base-flake \
  --no-write-lock-file --command quarto --version
```
