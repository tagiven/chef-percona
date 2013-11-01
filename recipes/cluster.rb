include_recipe "mysql::ruby"
include_recipe "percona::package_repo"

# install packages
case node["platform_family"]
when "debian"
  package "percona-xtradb-cluster-server-5.5" do
    options "--force-yes"
  end
when "rhel"
  package "mysql-libs" do
    action :remove
  end

  # Dependency of Percona Server
  include_recipe "yum::epel"

  package "socat" do
    action :install
  end

  package "Percona-XtraDB-Cluster-server"
end

include_recipe "percona::configure_server"

# access grants
include_recipe "percona::access_grants"
