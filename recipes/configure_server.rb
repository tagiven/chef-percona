percona = node["percona"]
server  = percona["server"]
conf    = percona["conf"]
mysqld  = (conf && conf["mysqld"]) || {}

# construct an encrypted passwords helper -- giving it the node and bag name
passwords = EncryptedPasswords.new(node, percona["encrypted_data_bag"])

template "/root/.my.cnf" do
  variables(:root_password => passwords.root_password)
  owner "root"
  group "root"
  mode 0600
  source "my.cnf.root.erb"
end

if server["bind_to"]
  ipaddr = Percona::ConfigHelper.bind_to(node, server["bind_to"])
  if ipaddr && server["bind_address"] != ipaddr
    node.override["percona"]["server"]["bind_address"] = ipaddr
    node.save unless Chef::Config[:solo]
  end

  log "Can't find ip address for #{server["bind_to"]}" do
    level :warn
    only_if { ipaddr.nil? }
  end
end

datadir = mysqld["datadir"] || server["datadir"]
user    = mysqld["username"] || server["username"]

# define the service
service "mysql" do
  supports :restart => true, :stop => true, :status => true
  action server["enable"] ? :enable : :disable
end

# this is where we dump sql templates for replication, etc.
directory "/etc/mysql" do
  owner "root"
  group "root"
  mode 0755
end

# setup the data directory
directory datadir do
  owner user
  group user
  recursive true
  action :create
end

# install db to the data directory
execute "setup mysql datadir" do
  command "mysql_install_db --user=#{user} --datadir=#{datadir}"
  not_if "test -f #{datadir}/mysql/user.frm"
end

# Boot strap initial node
execute "bootstrap cluster" do
  case node["platform_family"]
  when "rhel","fedora"
    command "service mysql bootstrap-pxc"
  when "debian"
    command "service mysql bootstrap-pxc"
  else
    command "service mysql bootstrap-pxc"
  end
  action :nothing
end

# Stop mysql prior to bootstrap
service "mysql" do 
  action :stop
end

# setup the main server config file
template percona["main_config_file"] do
  source "my.cnf.#{conf ? "custom" : server["role"]}.erb"
  owner "root"
  group "mysql"
  mode 0640
  if node["percona"]["cluster"]["bootstrap"] 
    notifies :run, resources(:execute => "bootstrap cluster"), :immediately if node["percona"]["auto_restart"]
  else
    notifies :restart, "service[mysql]", :immediately if node["percona"]["auto_restart"]
  end
end

# now let's set the root password only if this is the initial install
execute "Update MySQL root password" do
  command "mysqladmin --user=root --password='' password '#{passwords.root_password}'"
  if node["percona"]["server"]["role"] == "cluster"  
    not_if { Percona.is_root_password_set?("root",node["percona"]["server"]["root_password"] ) }
  else
    not_if "test -f /etc/mysql/grants.sql"
  end
end

# create SST User
execute "create SST user" do 
  command "mysql -e \"GRANT RELOAD,LOCK TABLES,REPLICATION CLIENT,CREATE TABLESPACE,SUPER ON *.* TO '#{node["percona"]["cluster"]["sst_user"]}'@'localhost' IDENTIFIED BY '#{node["percona"]["cluster"]["sst_password"]}';\""
  not_if { node["percona"]["cluster"]["sst_user"].empty? }
  action :run
end

# setup the debian system user config
template "/etc/mysql/debian.cnf" do
  source "debian.cnf.erb"
  variables(:debian_password => passwords.debian_password)
  owner "root"
  group "root"
  mode 0640

  if node["percona"]["cluster"]["bootstrap"]
    notifies :run, resources(:execute => "bootstrap cluster"), :immediately if node["percona"]["auto_restart"]
  else
    notifies :restart, "service[mysql]", :immediately if node["percona"]["auto_restart"]
  end

  only_if { node["platform_family"] == "debian" }
  action :nothing
end
