require 'socket'

def local_ip
  Socket.ip_address_list.detect(&:ipv4_private?).ip_address
end

Vagrant.configure("2") do |config|
  config.vm.define "windows2022" do |win|
    win.vm.box = "gusztavvargadr/windows-server-2022-standard"
    
    win.vm.provider "hyperv" do |h|
      h.memory = 4096  
      h.cpus = 4
      h.vmname = "Windows Server 2022"
    end
    
    win.vm.network "forwarded_port", guest: 3389, host: 3390, auto_correct: true

    win.vm.synced_folder ".", "/vagrant", type: "smb", smb_host: local_ip
    
    # Stage install files
    win.vm.provision "file", source: "git_install.inf", destination: "C:\\tmp\\git_install.inf"
    
    # For testing, run always
    win.vm.provision "shell", path: "startup.ps1", run: "always"
  end
end
