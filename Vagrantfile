Vagrant.configure("2") do |config|
  config.vm.box = "spox/ubuntu-arm"
  
  config.vm.provider "vmware_fusion" do |v|
    v.memory = 4096
    v.cpus = 2
  end

  # Nginx için port yönlendirmesi
  config.vm.network "forwarded_port", guest: 80, host: 8080

  # React Client için port yönlendirmesi
  config.vm.network "forwarded_port", guest: 3000, host: 3100
  
  # Backend için port yönlendirmesi
  config.vm.network "forwarded_port", guest: 5001, host: 5100

  # HTTP traffic için port forward
  config.vm.network "forwarded_port", guest: 80, host: 80
  config.vm.network "forwarded_port", guest: 443, host: 443

  # NodePort'lar için forward
  # NodePort için port yönlendirmesi
  config.vm.network "forwarded_port", guest: 30080, host: 30080
  
  # Minikube için private network
  config.vm.network "private_network", ip: "192.168.56.10"

  # Host-only network ekleyin
  config.vm.network "private_network", type: "dhcp"  
  
  config.vm.network "forwarded_port", guest: 30001, host: 30001

end