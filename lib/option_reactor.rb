module Jump
  
  require 'etc'
  require 'erb'

  # Class is used for executing the main meat of program
  # function, for each action there is coresponding method
  class OptionReactor

    def initialize(tpl_dir)
      @tpl_location = tpl_dir
    end

    # method reads template with specified name from template directory
    def loadTpl(tpl_name)
      return File.read(@tpl_location + tpl_name + '.erb' )
    end # loadTpl()

    # method loads private key from db data if we are root and if private
    # key is present in data
    def loadRootSshKeys(opts, data)
      if( !opts.sshKey && Process.uid == 0 && defined?(data[0]['private_key']) )
        opts.sshKey = data[0]['private_key']
      end
      
      return opts
    end # loadRootSshKeys()
    
    # method creates temporary file with private key, this is important
    # to be able to connect with ssh, temporary file is owned and readable
    # only and only by user running this script
    def prepareSshKeys(opts)
      
      # generating random number for temporary private key
      # like this nobody will have info to which server key file belongs
      random_seed = rand(10000000000)
      temp_ssh_key = ''

      if( opts.sshKey )

        temp_ssh_key = '/tmp/' + random_seed.to_s
        user_entry = Etc.getpwnam(opts.user)

        File.open(temp_ssh_key, 'w') { |fh| fh.puts opts.sshKey }
        File.chown(user_entry.uid, user_entry.gid, temp_ssh_key)
        File.chmod(0600, temp_ssh_key)

      end # if
      
      return temp_ssh_key
      
    end # prepareSshKeys()
    
    # method is main method used for all ssh connection, copying, cause
    # most of things are common, we are using yield to call action specific
    # code
    def ssh_connect(opts, data, config)

      connect_cmd_key = ''
      
      if( data.length == 0 )
        puts "No data"
        exit(11)
      end # if
      
      if( data.length > 1 )
        puts 'We got more than two records for host from database!'
        exit(11)
      end # if

      opts = self.loadRootSshKeys(opts, data)
      
      ssh_key = self.prepareSshKeys(opts)
      
      if( !ssh_key.empty? )
        connect_cmd_key = "-i #{ssh_key}"
      end # if
      
      # calling action specific code
      yield opts, data, connect_cmd_key

      # removing temporary file with private key, to be safe and not fill
      # temporary location
      if( File.exists?(ssh_key) )
        File.delete(ssh_key)
      end # if
      
    end # ssh_connect()
    
    # method used for outputing passed data, outputs differ just in template
    # so this is main method from which we call yield method with action
    # specific code
    def output(data, config, view_name)
      
      if( data.length == 0 )
        puts "No data"
        exit(11)
      end
      
      tpl = yield view_name
      pass = data
      cfg = config
      
      puts output = ERB.new(tpl, 0, '-').result(binding)
      
    end # output()
    
    # method executes main code for establishing ssh connection
    def connectAction(opts, data, config)

      self.ssh_connect(opts, data, config) { | opts, data, connect_cmd_key |
        connect_cmd = "ssh #{connect_cmd_key} " + opts.user + '@' + data[0]['ip_address']
        system(connect_cmd)
      }

    end # connectAction()

    # method executes main code for copying files and dirs from remote server
    # if we supply directory with / at the end turns on recursive copying
    def getAction(opts, data, config)

      self.ssh_connect(opts, data, config) { | opts, data, connect_cmd_key |
        
        ssh_opts = ''
      
        if( opts.from =~ /\/$/)
          ssh_opts = "-r"
        end
        
        connect_cmd = "scp #{ssh_opts} #{connect_cmd_key} " + opts.user + '@' + data[0]['ip_address'] + ":" + opts.from + " " + opts.to
        system(connect_cmd)
      }
      
    end # getAction()
    
    # method executes main code for copying files and dirs to remote server
    # if we supply directory with / at the end turns on recursive copying
    def putAction(opts, data, config)

      self.ssh_connect(opts, data, config) { | opts, data, connect_cmd_key |
        
        ssh_opts = ''
      
        if( opts.from =~ /\/$/)
          ssh_opts = "-r"
        end
        
        connect_cmd = "scp #{ssh_opts} #{connect_cmd_key} " + opts.from + " " + opts.user + '@' + data[0]['ip_address'] + ":"  + opts.to
        system(connect_cmd)
      }
      
    end # putAction()
    
    # method outputs data passed in format specified by template
    def listAction(opts, data, config)     
      
      view_name = 'list_view'
      
      self.output(data, config, view_name) { | view_name |
        tpl = loadTpl(view_name)
      }
    
    end # listAction()

    # method outputs data passed in format specified by template
    def searchAction(opts, data, config)
      self.listAction(opts, data, config)
    end # searchAction()

    # method outputs success message if data were added
    def addAction(opts, data, config)
      if(data > 0)
        puts "Adding host " + opts.server + " successful!"
      end # if
    end # addAction()

    # method outputs success message if data were deleted
    def deleteAction(opts, data, config)
      if(data > 0)
        puts "Deleting host successful!"
      end
    end # deleteAction()

    # method outputs data passed in format specified by template
    def detailAction(opts, data, config)
      view_name = 'detail_view'
      self.output(data, config, view_name) { | view_name |
        tpl = loadTpl(view_name)
      }
    end # detailAction()
    
    # method runs command on remote node and returns output
    def cmdAction(opts, data, config)
      self.ssh_connect(opts, data, config) { | opts, data, connect_cmd_key |
        connect_cmd = "ssh #{connect_cmd_key} " + opts.user + '@' + data[0]['ip_address'] + " '" + opts.command + "'"
        out = `#{connect_cmd}`
        puts out
      }
    end # cmdAction()
    
    # method runs script on remote node and returns output
    def scriptAction(opts, data, config)
      
      self.ssh_connect(opts, data, config) { | opts, data, connect_cmd_key |
        
        # we need to set /bin/bash -s to have non-interactive shell
        # so no banners etc.. are displayed
        connect_cmd = "ssh #{connect_cmd_key} " + opts.user
        connect_cmd += '@' + data[0]['ip_address'] + " '/bin/bash -s' <" + opts.from
        out = `#{connect_cmd}`
        puts out
        
      }
      
    end # scriptAction()
    
  end # class OptionReactor
  
end # module Jump
