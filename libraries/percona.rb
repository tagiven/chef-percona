class Chef::Recipe::Percona

  def self.is_root_password_set?(host, username, password)
    begin
      require 'mysql'
      m = Mysql.new(host, username, password)
      t = m.list_dbs
      return true
    rescue Exception => e
      return false
    end
  end

end
