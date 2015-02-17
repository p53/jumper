module Jump
  
  require 'etc'
  require 'erb'

  class OptionReactor

    def initialize(tpl_dir)
      @tpl_location = tpl_dir
    end

    def loadTpl(tpl_name)
      return File.read(@tpl_location + tpl_name + '.erb' )
    end

    def connectAction(opts, data)

      if( data.length > 1 )
        raise 'We got more than two records for host from database!'
      end

      if( !(defined?(opts.sshKey)) && Process.uid == 0 && defined?(data[0]['private_key']) )
        opts.sshKey = data[0]['private_key']
      end

      random_seed = rand(100000000)
      connect_cmd_key = ''
      temp_ssh_key = ''

      if( defined?(opts.sshKey) )

        temp_ssh_key = '/tmp/' + random_seed.to_s
        user_entry = Etc.getpwnam(opts.user)

        File.open(temp_ssh_key, 'w') { |fh| fh.puts opts.sshKey }
        File.chown(user_entry.uid, user_entry.gid, temp_ssh_key)
        File.chmod(0600, temp_ssh_key)

        connect_cmd_key = "-i #{temp_ssh_key}"

      end

      connect_cmd = "ssh #{connect_cmd_key} " + opts.user + '@' + data[0]['ip_address']

      system(connect_cmd)

      if( File.exists?(temp_ssh_key) )
        File.delete(temp_ssh_key)
      end

    end

    def listAction(opts, data)
      tpl = loadTpl('list_view')
      pass = data
      puts output = ERB.new(tpl, 0, '-').result(binding)
    end

    def searchAction(opts, data)
      tpl = loadTpl('search_view')
      pass = data
      puts output = ERB.new(tpl, 0, '-').result(binding)
    end

    def addAction(opts, data)
      if(data > 0)
        puts "Adding host " + opts.server + " successful!"
      end
    end

    def deleteAction(opts, data)
      if(data > 0)
        puts "Deleting host successful!"
      end
    end

  end
  
end
