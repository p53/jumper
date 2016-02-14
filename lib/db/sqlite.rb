module Jump
  module Db

    require 'etc'
    require 'sqlite3'

    # Class for handling data retrievals from sqlite3 database
    # it is singleton class
    class Sqlite

      private_class_method :new	

      # method for getting singleton instance
      def self.getSingleton(*args, &block)
        @@inst = new(*args, &block) unless defined?(@@inst)
        return @@inst
      end # getSingleton()

      # method for initializing object and db connection
      def initialize(db_params, data_dir)
        begin	
          @@connection = SQLite3::Database.open("#{data_dir}" + db_params['dbfile'])
        rescue SQLite3::Exception => e
          puts "Error occured" + e.to_s
        end # begin
      end # initialize()

      # method for getting data for connect action and handling db
      # errors
      def connectQuery(params)

        begin

          hostIdentifier = ''
          records = []
          # these fields can be used for host record retrieval
          avail_ident = {
            'host_name' => 'server',
            'ip_address' => 'address',
            'id_host' => 'serverId'
          }
          
          conn_query = "SELECT host_name, ip_address, private_key FROM host "
          conn_query += "WHERE "
          
          where_sql_arr = avail_ident.keys.map{ |db_col| 
            db_col += ' = :name ' 
          }
          
          conn_query += where_sql_arr.join('or ')

          stm = @@connection.prepare(conn_query)

          avail_ident.each{ | prop, prop_val |
            if( params.public_send(prop_val) )
              hostIdentifier = params.public_send(prop_val)
            end
          }

          rs = stm.execute(hostIdentifier)

          rs.each_hash do |row|
            records.push(row)
          end

        rescue SQLite3::Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        ensure
          stm.close if stm
        end # begin

        return records

      end # connectQuery()

      # method for getting host record for get cli action
      def getQuery(params)
        return self.connectQuery(params)
      end # getQuery()
      
      # method for getting host record for put cli action
      def putQuery(params)
        return self.connectQuery(params)
      end # putQuery()
      
      # method for getting host record for cmd cli action
      def cmdQuery(params)
        return self.connectQuery(params)
      end
      
      # method for getting host record for script cli action
      def scriptQuery(params)
        return self.connectQuery(params)
      end
      
      # method for getting host record for list cli action
      def listQuery(params)

        begin

          records = []

          stm = @@connection.prepare("SELECT id_host, host_name, ip_address, desc FROM host")

          rs = stm.execute()

          rs.each_hash do |row|
            records.push(row)
          end

        rescue SQLite3::Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        ensure
          stm.close if stm
        end # begin

        return records

      end # listQuery()

      # method for getting host record for search cli action
      # contains just simple like search
      def searchQuery(params)

        begin

          records = []

          search_query = "SELECT id_host, host_name, ip_address, desc FROM host WHERE "
          search_query += "host_name LIKE '%' || :name || '%' or ip_address "
          search_query += "LIKE '%' || :address || '%' or desc LIKE '%' || :desc || '%'"

          stm = @@connection.prepare(search_query)

          stm.bind_param('name', params.server)
          stm.bind_param('address', params.address)
          stm.bind_param('desc', params.desc)

          rs = stm.execute()

          rs.each_hash do |row|
                  records.push(row)
          end

         rescue SQLite3::Exception => e
            puts "Error occured" + e.to_s
            exit(14)
         ensure
          stm.close if stm
         end # begin

         return records

      end # searchQuery()
      
      # method for getting host record for add cli action
      def addQuery(params)

        begin

          affectedRows = 0

          add_query = "INSERT INTO host(host_name,ip_address,private_key, desc) "
          add_query += "VALUES(:name,:address,:key, :desc)"

          stm = @@connection.prepare(add_query)

          stm.bind_param(:name, params.server)
          stm.bind_param(:address, params.address)
          stm.bind_param(:key, params.sshKey)
          stm.bind_param(:desc, params.desc)

          rs = stm.execute()

          affectedRows = @@connection.changes

        rescue SQLite3::Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        ensure
          stm.close if stm
        end # begin

        return affectedRows

      end # addQuery()

      # method for getting host record for delete cli action
      def deleteQuery(params)

        begin

          affectedRows = 0

          stm = @@connection.prepare("DELETE FROM host WHERE id_host = :serverId")

          stm.bind_param(:serverId, params.serverId)

          rs = stm.execute()

          affectedRows = @@connection.changes

        rescue SQLite3::Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        ensure
          stm.close if stm
        end # begin

        return affectedRows

      end # deleteQuery()
      
      # method for getting host record for detail cli action
      # detail can be retrieved just by id
      def detailQuery(params)
        
        begin

          records = []

          hostIdentifier = "%"
          
          if( params.serverId )
            hostIdentifier = params.serverId
          end
          
          stm = @@connection.prepare("SELECT id_host, host_name, ip_address, desc FROM host WHERE id_host LIKE :id")

          rs = stm.execute(hostIdentifier)

          rs.each_hash do |row|
            records.push(row)
          end

        rescue SQLite3::Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        ensure
          stm.close if stm
        end # begin

        return records
        
      end # detailQuery()
      
    end # class Sqlite
    
  end # module Db
  
end # module Jump
