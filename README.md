# nix

This is the NixOS machine configuration for the [Open Computing Facility](https://ocf.berkeley.edu) at UC Berkeley.

## Layout

This is a heavy work-in-progress. I deployed the first thing that I found reasonable at first glance as a novice to Nix and NixOS.

## Why Nix?

We previously used to use Debian + [Puppet](https://github.com/ocf/puppet). However, while bringing up our new Kubernetes cluster in November 2022, we realized that this was not a good foundation to keep building on. There were a number of problems both with Puppet (TODO: dump some problems with puppet here), and Debian itself (TODO: dump some problems with debian here).

We evaluated Fedora CoreOS, thinking that maybe instead of doing configuration management, we just rebuild the world every time we wanted to change something with a butane (similar to cloud-init) file. [~njha](https://ocf.io/njha) gave it an honest shot for two weeks, building tooling to netboot and automatically provision nodes as well as a locking mechanism for auto updates. Unfortunately, CoreOS did not work out. Every basic thing (layering packages, configuring selinux rules, etc) needs to be written in the form of a systemd service. This makes our configuration really annoying! "But that's fine, since we don't need to touch our machine level configuration often" was just a wishful delusion. A lot of the ecosystem also just seems immature. We found lots of issues open for multiple years that need to be worked on. ~njha was going to work on them but then the list of issues grew way too long. If we're running into things like this repeatedly, Red Hat's use case for CoreOS is likely too different from ours to continue using Fedora CoreOS (which was surprising to us, because our use case is "run a fairly vanilla Kubernetes cluster on bare metal").

This repository is us evaluating Nix! I don't know if it will stick, but so far this is working out much better than CoreOS.

