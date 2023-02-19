# purifix

This is a Nix function for easily building PureScript projects with Nix.

The advantage of `purifix` is that your `spago.yaml` file acts as a
single source of truth.  When you update dependencies in `spago.yaml` you don't
need to update the Nix expression at all.  It automatically picks up changes
from the YAML file.

Using `purifix` on a PureScript package looks like the
following. This is how you would build the PureScript package
[`./examples/purescript-package/`](./examples/purescript-package/)
with `purifix`:


```nix
purifix {
  src = ./examples/purescript-package;
}
```

## Features

- `spago.yaml` as single source of truth.
- Compiles all package sets on the PureScript [registry](https://github.com/purescript/registry).
- Support for multiple PureScript backends.
- Support for bundling with `esbuild`.
- Incremental compilation (that is, you only compile `prelude` once)

  This is done by [manually merging the `cache-db.json` file generated by `purs`](https://github.com/purescript/spago/issues/527#issuecomment-566981224).

  You can disable incremental compilation with `{incremental = false;}`.
- Support for running tests with *Node.js*.
- Support for running the main module.
- Support for generating documentation and outputting markdown or html for your
  package and all of its dependencies.
- Support for monorepos and local packages installed from the file system.
- Support for entering a development shell where you can quickly compile your package sources.

## Installing / Getting `purifix`

The `purifix` function lives in this repo, and the recommended installation procedure is to include this flake and add the exported overlay to overlays when importing nixpkgs.

A simple package could be installed in a flake.nix file like below:

```nix
{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs";
    };
    purifix = {
      url = "github:purifix/purifix";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.purifix.overlay ];
        };
        my-package = pkgs.purifix {
          src = ./.;
        };
      in
      {
        packages = {
          default = my-package;
        };
        defaultPackage = my-package;
      });
}
```

You can also use `purifix` without flakes by importing the `purifix` function like so:
```nix
let
  purifix-src = builtins.fetchGit "https://github.com/purifix/purifix.git";
  purifix = import (purifix-src + "/nix") {};
in purifix {
  src = ./.;
}
```

It's recommended to pin the commit fetched with the `rev` attribute so that
your builds remain reproducible.

## Building the derivation produced by `purifix`

Building the derivation produced by `purifix` is as simple as calling
`nix-build` on it.  Here is how you would build the example PureScript package
in this repo:

```console
$ nix-build ./nix/examples.nix -A purifix-example
...
/nix/store/iyk9zzl7bwyvij4s67529xcmqlr3nqil-example-purescript-package-0.0.1
```

This produces an output with a single directory `output/`.  `output/` contains
all the transpiled PureScript code:

```console
$ tree /nix/store/hjcxs72xkjm4qad78railg6kflbljpcz-example-purescript-package-0.0.1
/nix/store/hjcxs72xkjm4qad78railg6kflbljpcz-example-purescript-package-0.0.1
└── output
    ├── cache-db.json
    ├── Control.Alt
    │   ├── docs.json
    │   ├── externs.cbor
    │   └── index.js
    ├── Control.Alternative
    │   ├── docs.json
    │   ├── externs.cbor
...
```
## Creating a package

This repository contain some [example packages](./examples) to show how to get
started using `purifix` to build your PureScript sources. Below is a minimal
`spago.yaml` defining how to build all the PureScript in the src directory.

Required fields are `name`, `version`, `dependencies` and `package_set`.

```yaml
package:
  name: example-purescript-package
  version: 0.0.1
  dependencies: [ "console", "effect", "foldable-traversable", "prelude"]
workspace:
  package_set:
    registry: 11.3.0
```

## Developing using `purifix`

To create a development shell where you can easily compile your package sources
without having to wait for a full `nix build` you can run `nix develop` or
`nix-shell` on the `develop` attribute of your `purifix` package.


```nix
(purifix {
  src = ./examples/purescript-package;
}).develop
```

This will place you in a shell where you have the `purifix` executable. This executable
will copy the precompiled dependencies to the `output` directory and then only compile your
package-specific files.

```console
$ purifix src/Main.purs
```

will compile the `Main.purs` file and place the result in the `output` directory together with
the precompiled dependencies.

### Using `purescript-language-server`

You can use `purescript-language-server` with `purifix`. Make sure that you
include `spago.yaml` when finding the root of your PureScript package.

Below is an example of configuring
[coc.nvim](https://github.com/neoclide/coc.nvim) to use the
purescript-language-server.

```json
    "purescript": {
      "command": "purescript-language-server",
      "args": ["--stdio"],
      "filetypes": ["purescript"],
      "trace.server": "off",
      "rootPatterns": ["spago.yaml", "psc-package.json", "spago.dhall"],
      "settings": {
        "purescript": {
          "addSpagoSources": true,
          "addNpmPath": true
        }
      }
    }
```

Before you load your project with the `purescript-language-server` it can be
useful to run `purifix` in the development shell so that you don't have to
compile all your dependencies again.

## Creating an application bundle

```nix
(purifix {
  src = ./examples/purescript-package;
}).bundle {
  format = "iife";
  minify = true;
  app = true;
}
```

## Monorepos

You can use `purifix` with monorepos by making use of the `subdir` attribute.

Set the `src` attribute of the call to `purifix` the root of your repository
and specify the `subdir` to be a relative path from the root to the package you
want to build.

```nix
purifix {
  subdir = "example-registry-package";
  src = ./examples;
}
```

## Running tests

```nix
(purifix {
  subdir = "example-registry-package";
  src = ./examples;
}).test
```

## Running the main module with `node`

```nix
(purifix {
  subdir = "example-registry-package";
  src = ./examples;
}).run
```

```console
$ nix build .#example-registry-package-run --out-link result
$ ./result/bin/example-purescript-package
🍝
1337
```

This can also be packaged as an [app in a flake](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-run.html#flake-output-attributes). The executable is given the same name as the package.

## Generating documentation

You can generate documentation for your package with

```nix
(purifix {
  src = ./examples/purescript-package;
}).docs {
  format = "html";
}
```
