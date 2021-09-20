---
title: Nomad & Consul Cluster for testing CSI
author: Leela Venkaiah G
slug: "nomad-csi"
env:
    - eval $(shipyard env)
shipyard_version: ">= 0.3.30"
---

# Local Development/Testing of CSI in Nomad & Consul

## Shipyard Installation
- Refer shipyard [docs](https://shipyard.run/docs/install) for installing shipyard on your local machine
- Clone current [repo](https://github.com/leelavg/kadalu-nomad/) for bringing up Nomad & Consul cluster with defaults to use Kadalu (or any) CSI
- You can refer shipyard docs to use current repo as shipyard module and ya, clone and run command `shipyard run` also would do
- Refer hcl files in the repo to make any adjustments

## Shipyard Run
- `cd` to current local repo and run `shipyard run` and wait for it's completion
- You can install `nomad` (binary)[https://www.nomadproject.io/docs/install] for talking with Nomad agent created by Shipyard or use the same container as well (former is preferred)
- In general, nomad will be running on port `4646` but shipyard brings it up on an arbitrary port
- Before using `nomad` binary run `eval $(shipyard env)`

## Using Kadalu
- Not to re-iterate steps here for running Kadalu CSI in Nomad, please refer Kadalu [repo](https://github.com/kadalu/kadalu/tree/devel/nomad)

Thanks @nicholasjackson for pushing fixes wrt Nomad configs and @eveld for quick ack's in [discord](https://discord.gg/ZuEFPJU69D)
