require 'socket'

def local_ip
  Socket.ip_address_list.detect(&:ipv4_private?).ip_address
end

Vagrant.configure("2") do |config|
  config.vm.box = "gusztavvargadr/windows-server-2022-standard"
  
  config.vm.provider "hyperv" do |h|
    h.memory = 4096  
    h.cpus = 2
    h.vmname = "HollyHockDev - Windows Server 2022"
  end
  
  config.vm.network "forwarded_port", guest: 3389, host: 3390, auto_correct: true

  config.vm.synced_folder ".", "/vagrant", type: "smb", smb_host: local_ip
  
  # Stage install files
  config.vm.provision "file", source: "git_install.inf", destination: "C:\\tmp\\git_install.inf"
  
  # For testing, run always
  config.vm.provision "shell", path: "startup.ps1", run: "always"

end