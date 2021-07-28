# mars-std

A set of reusable Nix utilities for Mars Research projects.

## Quickstart

If you don't have Nix installed yet, we recommend installing the unstable version of Nix with Flakes support:

```
sh <(curl -L https://github.com/numtide/nix-flakes-installer/releases/download/nix-2.4pre20210604_8e6ee1b/install) --daemon
```

### Cloudlab

Use the following image which has Nix 2.4 pre-installed and configured with our binary cache:

```
urn:publicid:IDN+wisc.cloudlab.us+image+redshift-PG0:ubuntu-2004-mars-research
```

## FAQ

### I'm running macOS. How can I get things to work?

Nix works on macOS but much of our setup depends on Linux.
It's suggested that you develop on [Cloudlab](https://www.cloudlab.us).

### I have already installed stable Nix with the installer script. How can I upgrade to the unstable version (Nix 2.4)?

*Note: This only applies to people who installed using [the installer script](https://nixos.org/download.html) on nixos.org.* 

(Quoted from [the Nix manual](https://nixos.org/manual/nix/unstable/installation/upgrading.html))

- For single-user installations: `nix-channel --update; nix-env -iA nixpkgs.nixUnstable nixpkgs.cacert`
- For multi-user / `--daemon` installations: `nix-channel --update; nix-env -iA nixpkgs.nixUnstable nixpkgs.cacert; systemctl daemon-reload; systemctl restart nix-daemon` (with sudo)

### What are the recommended attributes to export?

- `reproduce`: A shell hook that runs the experiment and prints human-readable results. Should be runnable with `nix-shell -A reproduce`.
