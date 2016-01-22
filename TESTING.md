# Testing Documentation

## Prerequisites
VSTS Build Agent cookbook requires ChefDK installation. ChefDK can be downloaded at https://downloads.chef.io/chef-dk/

Integration testing uses Hashicorp's [Vagrant](https://www.vagrantup.com/downloads.html) and Oracle's [Virtualbox](https://www.virtualbox.org/wiki/Downloads), which must be installed first.

## Style Testing
Ruby and Chef([Foodcritic](http://www.foodcritic.io/)) style checks can be performed by running:
```
chef exec rake style
```
or
```
rake style
```

## Integration Testing
Integration tests are orchestrated by [test-kitchen](https://github.com/test-kitchen/test-kitchen). Currently kitchen.yml contains mix of public(linux) and private boxes(Windows and MacOSX). Windows and MacOSX boxes can be built locally with help of Hashicorp's [packer](https://www.packer.io/) tool.
:small_red_triangle:NOTE: To use MacOSX boxes you need an Apple-branded computer.

Additionally you need [vsts account url](https://www.visualstudio.com/en-us/get-started/setup/sign-up-for-visual-studio-online), username, [personal access token](http://roadtoalm.com/2015/07/22/using-personal-access-tokens-to-access-visual-studio-online/) and [pool name](http://blog.devmatter.com/understanding-pools-and-queues-in-vso/).

Set environment variables

on windows:
```
set VSTS_URL=account.visualstudio.com
set VSTS_POOL=default
set VSTS_USER=username
set VSTS_TOKEN=my_secret_token_from_vsts
```
on linux or macosx:
```
export VSTS_URL=account.visualstudio.com
export VSTS_POOL=default
export VSTS_USER=username
export VSTS_TOKEN=my_secret_token_from_vsts
```

To run test against specific platform run:
```
kitchen verify PLATFORM
```

Available platforms:
* debian7 (public)
* ubuntu1404 (public)
* centos6 (public)
* osx109-desktop (private)
* windows10 (private)
* windows81 (private)
