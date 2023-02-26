let
  flake-lock = builtins.fromJSON (builtins.readFile ./flake.lock);

  nixpkgs-src = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${flake-lock.nodes.nixpkgs.locked.rev}.tar.gz";
    sha256 = flake-lock.nodes.nixpkgs.locked.narHash;
  };

  purescript-registry = builtins.fetchTarball {
    url = "https://github.com/purescript/registry/archive/${flake-lock.nodes.purescript-registry.locked.rev}.tar.gz";
    sha256 = flake-lock.nodes.purescript-registry.locked.narHash;
  };

  purescript-registry-index = builtins.fetchTarball {
    url = "https://github.com/purescript/registry-index/archive/${flake-lock.nodes.purescript-registry-index.locked.rev}.tar.gz";
    sha256 = flake-lock.nodes.purescript-registry-index.locked.narHash;
  };

  easy-purescript-nix = builtins.fetchTarball {
    url = "https://github.com/justinwoo/easy-purescript-nix/archive/${flake-lock.nodes.easy-purescript-nix.locked.rev}.tar.gz";
    sha256 = flake-lock.nodes.easy-purescript-nix.locked.narHash;
  };
  overlay = import ./nix/overlay.nix { inherit purescript-registry purescript-registry-index easy-purescript-nix; };
in
{ pkgs ? import nixpkgs-src { } }:

# Nixpkgs with overlays for purifix.  This is convenient to use with
# `nix repl`:
#
# $ nix repl ./nix
# nix-repl>
#
# Within this nix-repl, you have access to everything defined in ./overlay.nix.


let

  final = pkgs.extend overlay;

in
final.purifix // { pkgs = final; }
