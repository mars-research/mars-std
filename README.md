# mars-std

A set of reusable Nix utilities for Mars Research projects.

## Quickstart

If you don't have Nix installed yet, we recommend using the following command to install Nix in the multi-user mode:

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### CloudLab

Use the following image which has NixOS 21.11 installed and configured with our binary cache:

```
urn:publicid:IDN+wisc.cloudlab.us+image+redshift-PG0:nixos-2111-mars-research
```

## FAQ

### I'm running macOS. How can I get things to work?

Nix works on macOS but much of our setup depends on Linux.
It's suggested that you develop on [Cloudlab](https://www.cloudlab.us).

### What are the recommended attributes to export?

- `reproduce`: A shell hook that runs the experiment and prints human-readable results. Should be runnable with `nix-shell -A reproduce`.
