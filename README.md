# Diamond network Dpass ERC-721 smart contract

One of the main purposes of [Diamond Network Project](https://cdiamondcoin.com/) is to create a diamond backed stable coin. Each diamond has his own Dpass contract with purchase history, attributes like price, sale ability and etc. To use the services of the platform you will need a utility token called [DPT - Diamond Platform Token](https://github.com/Cdiamondcoin/dpt-token). Current repository contains the [ERC721](https://github.com/ethereum/EIPs/issues/721) compatible smart contract of Dpass token.

## Prerequisities

In order to compile smart contracts you need to install [Dapphub](https://dapphub.com/)'s utilities. Namely: [dapp](https://dapp.tools/dapp/), [seth](https://dapp.tools/seth/), [solc](https://github.com/ethereum/solidity), [hevm](https://dapp.tools/hevm/), and [ethsign](https://github.com/dapphub/dapptools/tree/master/src/ethsign).

| Command | Description |
| --- | --- |
|`bash <(curl https://nixos.org/nix/install)` | install `nix` package manager.|
|`. "$HOME/.nix-profile/etc/profile.d/nix.sh"`| load config for `nix`|
|`git clone --recursive https://github.com/dapphub/dapptools $HOME/.dapp/dapptools` | download `dapp seth solc hevm ethsign` utilities|
|`nix-env -f $HOME/.dapp/dapptools -iA dapp seth solc hevm ethsign` | install `dapp seth solc hevm ethsign`. This will install utilities for current user only!!|

## Installing smart contracts

As a result of installation .abi and .bin files will be created in `dpt-token/out/` folder. These files can be installed later on mainnet.

| Command | Description |
| --- | --- |
|`git clone https://github.com/Cdiamondcoin/dpass.git` | Clone the smart contract code.|
|`cd dpass && git submodule update --init --recursive` | Update libraries to the latest version.|
|`cd lib/openzeppelin-solidity/ && ln -s contracts src` | Make openzeppelin lib compatible with dapp tools.|
|`cd ../../  && dapp test` | Compile and test the smart contracts.|

## Building smart contracts

The `build` command invokes `solc` to compile all code in `src` and `lib` to `out`.

`dapp build`

## Deploying smart contracts

In order to deploy smart contracts you need to do the followings.
- Deploy `dpass/out/Dpass.abi` `dpass/out/Dpass.bin` to install Dpass smart contract.

## Authors

- [Vitālijs Gaičuks](https://github.com/vgaicuks)
- [Robert Horvath](https://github.com/r001)

## License

This project is licensed under the GPL v3 License - see the [LICENSE](LICENSE) for details.
