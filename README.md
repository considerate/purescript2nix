# purescript2nix

This is a Nix function for easily building PureScript projects with Nix.

The advantage of `purescript2nix` is that your `spago.yaml` file act as a
single source of truth.  When you update dependencies in `spago.yaml` you don't
need to update the Nix expression at all.  It automatically picks up changes
from the YAML file.

Using `purescript2nix` on a PureScript packages looks like the
following. This is how you would build the PureScript package
[`./example-registry-package/`](./example-registry-package/)
with `purescript2nix`:


```nix
purescript2nix {
  src = ./example-purescript-package;
}
```

## Installing / Getting `purescript2nix`

The `purescript2nix` function lives in this repo, and the recommend installation procedure is to include this flake and add the exported overlay to overlays when importing nixpkgs.

A simple package could be installed in a flake.nix file like below:

```nix
{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs";
    };
    purescript2nix = {
      url = "github:cdepillabout/purescript2nix";
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
          overlays = [ inputs.purescript2nix.overlay ];
        };
        my-package = pkgs.purescript2nix {
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

## Building the derivation produced by `purescript2nix`

Building the derivation produced by `purescript2nix` is as simple as calling
`nix-build` on it.  Here is how you would build the example PureScript package
in this repo:

```console
$ nix-build ./nix -A example-registry-package
...
/nix/store/z3gvwhpnp0rfi65dgxmk1rjycpa4l1ag-example-purescript-package
```

This produces an output with a single directory `output/`.  `output/` contains
all the transpiled PureScript code:

```console
$ tree /nix/store/z3gvwhpnp0rfi65dgxmk1rjycpa4l1ag-example-purescript-package
/nix/store/z3gvwhpnp0rfi65dgxmk1rjycpa4l1ag-example-purescript-package
└── output
    ├── cache-db.json
    ├── Control.Alt
    │   ├── externs.cbor
    │   └── index.js
    ├── Control.Alternative
    │   ├── externs.cbor
    │   └── index.js
    ├── Control.Applicative
    │   ├── externs.cbor
    │   └── index.js
    ├── Control.Apply
    │   ├── externs.cbor
    │   ├── foreign.js
...
```


- `spago.yaml` as single source of truth.
- Support for multiple PureScript backends.
- Support for bundling with `esbuild`.
- incremental compilation (that is, you only compile __prelude__ once)

  This is done by [manually merging the `cache-db.json` file generated by `purs`](https://github.com/purescript/spago/issues/527#issuecomment-566981224).
  
  You can disable incremental compilation with `{incremental = false}`.
- Support for running tests with *Node.js*.
- Support for entering a development shell where you can quickly compile just your package sources.
