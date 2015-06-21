# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.define "firebrick-dev" do |named_vm|
    named_vm.vm.box = "ubuntu/trusty64"
    named_vm.vm.network "private_network", ip: "33.33.33.10"

    shell_commands = [
      "echo '#{`cat ~/.ssh/id_rsa.pub`}' | sudo tee -a /root/.ssh/authorized_keys"
    ]

    named_vm.vm.provision "shell",
      inline: shell_commands.join("; "),
      privileged: false
  end

end
