class Chef::Recipe::Percona

  def self.is_root_password_set?(username, password)
    m = system("mysql -u #{username} -p#{password} -e 'STATUS;'")
      
    if m
      print "Database Connection successful"
    else
      print "Database Connection failed"
    end

    print "\n\nconnection status: #{m}\n\n"
    return m
  end
end

