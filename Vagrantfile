username = `whoami`.strip

nodes = [
    { :hostname => username + 'VM', :ip => '192.168.56.110'},
]

Vagrant.configure("2") do |config|
    nodes.each do |node|
        config.vm.define node[:hostname] do |nodeconfig|
            nodeconfig.vm.provider "virtualbox" do |v|
                v.name = node[:hostname]
                v.cpus = 1
                v.memory = 1024
            end
            nodeconfig.vm.box = "debian/bullseye64"
            nodeconfig.vm.hostname = node[:hostname]

            nodeconfig.vm.network "private_network", ip: node[:ip]
            nodeconfig.ssh.insert_key = false

            nodeconfig.vm.synced_folder ".", "/vagrant", type: "virtualbox"

            if (node[:hostname] == nodes[0][:hostname])
                nodeconfig.vm.provision "shell", path: "VMSetup.sh",
                privileged: true
            end
        end 
    end
end