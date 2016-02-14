module Jump
  
  require 'optparse'
  require 'optparse/time'
  require 'ostruct'
  require 'pp'
  require 'etc'

  # Class is used for parsing CLI arguments
  # and checking if they align with constraints
  class JumpArgParser

    # method does arguments parsing and base checking
    def self.parse(args)

      options = OpenStruct.new

      opt_parser = OptionParser.new() do |opts|

        opts.on(
          "-a", 
          "--action [list|search|connect|add|delete|detail|get|put|cmd|script]",
          [:list, :search, :connect, :add, :delete, :detail, :get, :put, :cmd, :script], 
          "Action you want to perform",
          "On action depends which arguments you will need to pass",
          "list - doesn't require arguments",
          "connect - you must pass server or ip or id, you can set user also private key",
          "add - you must supply: server, ip, description - requires root privileges",
          "delete - requires id - requires root privileges",
          "search - you can search by host, ip, description",
          "detail - lists records in key value format, if id specified, shows just specified record",
          "get - copies from remote server, requires from and to argument",
          "put - copies to remote server, requires from and to argument",
          "cmd - executes command on remote server, requires command argument",
          "script - executes script on remote server, requires from argument"
        ) do |action|
          options.action = action
        end

        opts.on("-s", "--server Hostname", "Name of host on which we want to apply action") do  |host|
          options.server = host
        end

        opts.on("-i", "--ip IP address", "IP address of host on which we want to apply action") do |address|
          options.address = address
        end

        opts.on("-u", "--user User", "User name as which we want to connect on machine") do |user|
          options.user = user
        end

        opts.on("-k", "--priv_key Path", "Path to SSH private key") do |privKey|
          options.privKey = privKey
        end

        opts.on("-n", "--id ID", "Id of the server record in database") do |serverId|
          options.serverId = serverId
        end

        opts.on("-d", "--desc Text", "Description of server record") do |desc|
          options.desc = desc
        end

        opts.on("-f", "--from Path", "Path to file or dir on local/remote server ") do |from|
          options.from = from
        end
        
        opts.on("-t", "--to Path", "Path to file or dir on local/remote server ") do |to|
          options.to = to
        end
                
        opts.on("-c", "--command String", "Command to execute on remote server ") do |command|
          options.command = command
        end
        
        opts.on("-h", "--help", "Prints help") do
          puts opts
          exit
        end

      end # do

      opt_parser.parse!(args)

      # we are checking if we supplied some arguments
      if(options.marshal_dump().length() == 0)
        puts opt_parser.help()
        exit(10)
      end # if
      
      # we need to get user under which current script runs
      # if user wasn't directly supplied, this will be user
      # passed to ssh connection
      user_id = Process.uid
      user_entry = Etc.getpwuid(user_id)

      if( !(options.user) )
        options.user = user_entry.name
      end # if

      # if we supply private key file on cli, read that file
      # otherwise try to find ssh key with same name as server in
      # user home directory
      if( defined?(options.privKey) )
          if( File.readable?(options.privKey) )
            options.sshKey = File.read(options.privKey)
          end # if
      else

        entry = Etc.getpwnam(options.user)

        if( defined?(options.server) )
          try_file = entry.dir + '/.ssh/' + options.server

          if( File.readable?(try_file) )
            options.sshKey = File.read(try_file)
          end # if
        end # if
        
      end # if
      
      # we are running additional checks, specific for each
      # action, checking dependencies between arguments etc..
      check_method = options.action

      if( check_method )
        
        if( self.respond_to?(check_method) )
          self.public_send(check_method, options, opt_parser)
        else
          puts opt_parser.help()
          exit(10)
        end # if
        
      else
        puts opt_parser.help()
        exit(10)
      end # if

      return options

    end # parse()

    # method checks parameters needed to get data and establish ssh connection
    def self.connect(opts, parser)

      if( !(opts.server) && !(opts.address) && !(opts.serverId) )
        puts parser.help()	
        exit(10)
      end # if

    end # connect()

    # method checks params for listing
    def self.list(opts, parser)  
    end
    
    # method for checking params for server addition
    # also reads private key if supplied on cli
    def self.add(opts, parser)

      if( Process.uid != 0 )
        puts "This action requires root privileges!"
        exit(11)
      end # if
      
      if( !(opts.server) || !(opts.address) || !(opts.desc) )
        puts parser.help()
        exit(10)	
      end # if

    end # add()

    # method checks params for searching
    def self.search(opts, parser)

      if( !(opts.server) && !(opts.address) && !(opts.desc) )
        puts parser.help()
        exit(10)
      end # if

    end # search()
    
    # method checks params for deletion
    def self.delete(opts, parser)
      
      if( Process.uid != 0 )
        puts "This action requires root privileges!"
        exit(11)
      end
      
      if( !(opts.serverId) )
        puts parser.help()
        exit(10)
      end # if

    end # delete()

    # method checks params for showing details
    def self.detail(opts, parser)
    end # detail()
    
    # method checks params for getting files from servers
    def self.get(opts, parser)
      if( !(opts.from) || !(opts.to) || ( !opts.server && !opts.address) )
        puts parser.help()
        exit(10)
      end # if
    end # get()
    
    # method checks params for putting files on server
    def self.put(opts, parser)
      if( !(opts.from) || !(opts.to) || ( !opts.server && !opts.address) )
        puts parser.help()
        exit(10)
      end # if
    end # put()
    
    # method checks params for executing command on remote server
    def self.cmd(opts, parser)
      if( !opts.command || ( !opts.server && !opts.address) )
        puts parser.help()
        exit(10)
      end # if
    end # cmd()
    
    # method checks params for executing script on remote server
    def self.script(opts, parser)
      
      if( !opts.from || ( !opts.server && !opts.address) )
        puts parser.help()
        exit(10)
      end # if
      
      if( !File.exists?(opts.from) || !File.readable?(opts.from) )
        puts "File does not exist or is not readable!"
        exit(15)
      end # if
      
    end # script()
    
  end # class JumpArgParse

end # module Jump