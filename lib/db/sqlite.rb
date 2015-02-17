module Jump
  module Db

    require 'etc'
    require 'sqlite3'
    require 'singleton'

    class Sqlite

      private_class_method :new	

      def self.getSingleton(*args, &block)
        @@inst = new(*args, &block) unless defined?(@@inst)
        return @@inst
      end

      def initialize(db_params, data_dir)
        begin	
          @@connection = SQLite3::Database.open("#{data_dir}" + db_params['dbfile'])
        rescue SQLite3::Exception => e
          puts "Error occured" + e.to_s
        end
      end

      def connectQuery(params)

        begin

          hostIdentifier = ''
          records = []

          stm = @@connection.prepare("SELECT host_name, ip_address, private_key FROM host WHERE host_name = :name or ip_address = :name")

          if(params.server)
            hostIdentifier = params.server
          else
            hostIdentifier = params.address
          end

          rs = stm.execute(hostIdentifier)

          rs.each_hash do |row|
            records.push(row)
          end

        rescue SQLite3::Exception => e
          puts "Error occured" + e.to_s
        ensure
          stm.close if stm
        end

        return records

      end

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
        ensure
                stm.close if stm
        end

        return records

      end

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
         ensure
                 stm.close if stm
         end

         return records

      end

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
                puts "Error occured" + e
        ensure
                stm.close if stm
        end

        return affectedRows

      end

      def deleteQuery(params)

        begin

          affectedRows = 0

          stm = @@connection.prepare("DELETE FROM host WHERE id_host = :serverId")

          stm.bind_param(:serverId, params.serverId)

          rs = stm.execute()

          affectedRows = @@connection.changes

        rescue SQLite3::Exception => e
                puts "Error occured" + e
        ensure
                stm.close if stm
        end

        return affectedRows

      end

    end # class Sqlite
  end
end
