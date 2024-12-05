{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem(system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      new-day = pkgs.writeScriptBin "new-day" (builtins.readFile ./scripts/new-day.sh);
      next-day = pkgs.writeScriptBin "next-day" (builtins.readFile ./scripts/next-day.sh);

    in {
      devShell = pkgs.mkShell {
        packages = with pkgs; [
          gleam
          erlang_26
          new-day
          next-day
        ];
      };
    }
  );
}
