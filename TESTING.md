# Testing Documentation

## Prerequisites
VSTS Build Agent cookbook requires ChefDK installation - download it [here](https://downloads.chef.io/chef-dk/).

Integration testing uses Hashicorp's [Vagrant](https://www.vagrantup.com/downloads.html) and Oracle's [Virtualbox](https://www.virtualbox.org/wiki/Downloads), which must be installed first.

You'll also need the following from VSTS:
- Username
- [Account URL](https://www.visualstudio.com/en-us/get-started/setup/sign-up-for-visual-studio-online)
- [Personal access token](http://roadtoalm.com/2015/07/22/using-personal-access-tokens-to-access-visual-studio-online/)
- [Build pool name](http://blog.devmatter.com/understanding-pools-and-queues-in-vso/)

### Integration testing using boxes and Virtualbox
Integration tests are orchestrated by [test-kitchen](https://github.com/test-kitchen/test-kitchen).
Although Linux boxes are freely available from Vagrant's repository, for Mac and Windows, you'll need to build your own using Hashicorp's [Packer](https://www.packer.io/).

#### Guides for building Mac and Windows boxes
- [Mac VM templates for Packer and VeeWee](https://github.com/timsutton/osx-vm-templates)
- [Windows Packer templates](https://github.com/joefitzgerald/packer-windows)
- [Boxcutter](https://github.com/boxcutter) (All platforms)


### Running the tests
#### Set environment variables

Windows:
```
set VSTS_URL='https://account.visualstudio.com'
set VSTS_POOL=default
set VSTS_USER=username
set VSTS_TOKEN=my_secret_token_from_vsts
```
Linux / Mac:
```
export VSTS_URL='https://account.visualstudio.com'
export VSTS_POOL=default
export VSTS_USER=username
export VSTS_TOKEN=my_secret_token_from_vsts
```

If the username of the box you're testing differs from standard "vagrant":
```
export BOX_USERNAME=username
```

#### Executing the tests
The `kitchen test` instance states are in order: destroy, create, converge, setup, verify, destroy. `kitchen test` changes the state of one or more instances to destroyed, then executes the actions for each state up to destroy. At any sign of failure, executing the actions stops and the instance is left in the last successful execution state.
```
kitchen test VAGRANT_BOX_NAME
```

#### Examples:
`$ kitchen test osx1010`  
`$ kitchen test windows_2012_r2`  
`$ kitchen test ubuntu1604`


:small_red_triangle: The Windows and Mac boxes must be [built](#guides-for-building-mac-and-windows-boxes) prior to testing. Once built, you'll need to modify the `.kitchen.yml` file. To find out list of available boxes and their names, simply execute `vagrant box list`. See the [Chef documentation](https://docs.chef.io/config_yml_kitchen.html) or comments in `.kitchen.yml` for how to modify it for your boxes.

#### Style Testing
Several style checks can be performed by running any of the following:

`$ chef exec rake style`  
`$ rake style`  
`$ foodcritic .`  
`$ rubocop .`  
