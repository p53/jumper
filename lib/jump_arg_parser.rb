module Jump
  
  require 'optparse'
  require 'optparse/time'
  require 'ostruct'
  require 'pp'
  require 'etc'

  class JumpArgParser

    def self.parse(args)

      options = OpenStruct.new

      opt_parser = OptionParser.new() do |opts|

        opts.on(
          "-a", 
          "--action [list|search|connect|add|delete]",
          [:list, :search, :connect, :add, :delete], 
          "Action you want to perform",
          "On action depends which arguments you will need to pass",
          "list - doesn't require arguments",
          "connect - you must pass server or ip, you can set user also private key",
          "add - you must supply: server, ip, description - requires root privileges",
          "delete - requires id - requires root privileges",
          "search - you can search by host, ip, description"
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

        opts.on("-h", "--help", "Prints help") do
          puts opts
          exit
        end

      end # do

      opt_parser.parse!(args)

      if(options.marshal_dump().length() == 0)
        puts opt_parser.help()
        exit(10)
      end # if
      
      user_id = Process.uid
      user_entry = Etc.getpwuid(user_id)

      if( !(options.user) )
        options.user = user_entry.name
      end # if

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

    def self.connect(opts, parser)

      if( !(opts.server) && !(opts.address) )
        puts parser.help()	
        exit(10)
      end # if

      if( defined?(opts.privKey) )
          if( File.readable?(opts.privKey) )
            opts.sshKey = File.read(opts.privKey)
          end # if
      else

        entry = Etc.getpwnam(opts.user)
        try_file = entry.dir + '/.ssh/' + opts.server

        if( File.readable?(try_file) )
          opts.sshKey = File.read(try_file)
        end # if

      end # if

    end # connect()

    def self.list(opts, parser)  
    end
    
    def self.add(opts, parser)

      if( Process.uid != 0 )
        puts "This action requires root privileges!"
        exit(11)
      end # if
      
      if( !(opts.server) || !(opts.address) || !(opts.desc) )
        puts parser.help()
        exit(10)	
      end # if

      if( defined?(opts.privKey) )
        if( File.readable?(opts.privKey) )
          opts.sshKey = File.read(opts.privKey)
        end # if
      end # if

    end # add()

    def self.search(opts, parser)

      if( !(opts.server) && !(opts.address) && !(opts.desc) )
        puts parser.help()
        exit(10)
      end # if

    end # search()

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

  end # class JumpArgParse

end # module Jump