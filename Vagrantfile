# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.hostname = "percona"
  case ENV['VMBOX']
  when 'centos64'
    config.vm.box = "CentOS-6.4-x86_64-minimal"
    config.vm.box_url = "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130427.box"
  else
    config.vm.box = "vagrant-ubuntu-12.04"
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  end
  config.vm.network :private_network, ip: "33.33.33.10"
  # config.ssh.max_tries = 40
  # config.ssh.timeout   = 120
  # config.omnibus.chef_version = :latest
  config.omnibus.chef_version = "11.4.4"
  config.berkshelf.enabled = true

  config.vm.provision :chef_solo do |chef|
    chef.log_level = :debug
    chef.json = {
      :percona => {
        :server => {
          :includedir => ""
        }
      }
    }
    chef.run_list = [
      "recipe[percona::package_repo]",
      "recipe[percona::server]"
    ]
  end
end
