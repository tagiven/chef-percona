class Chef::Recipe::Percona

  def self.is_root_password_set?(host, username, password)
    begin
      print "#{host} #{username} #{password}"
      require 'mysql'
      m = Mysql.new(host, username, password)
      print "Connection successful"
      t = m.list_dbs
      print "list successful"
      return true
    rescue Exception => e
      print "database connection not successful"
      return false
    end
  end

end
