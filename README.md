# nix

This is the NixOS machine configuration for the [Open Computing Facility](https://ocf.berkeley.edu) at UC Berkeley.

## Layout

This is a heavy work-in-progress. I deployed the first thing that I found reasonable at first glance as a novice to Nix and NixOS.

## Why Nix?

We previously used to use Debian + [Puppet](https://github.com/ocf/puppet). However, while bringing up our new Kubernetes cluster in November 2022, we realized that this was not a good foundation to keep building on. There were a number of problems both with Puppet (TODO: dump some problems with puppet here), and Debian itself (TODO: dump some problems with debian here).

This repository is us evaluating Nix! I don't know if it will stick, but so far this is working out much better than CoreOS.

