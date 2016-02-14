module Jump
  module Db
    
    require "zabbixapi"
              
    # Class for handling data retrievals from zabbix 2.2 server
    # it is singleton class
    class Zabbix22
      
      private_class_method :new	

      # method for getting singleton instance
      def self.getSingleton(*args, &block)
        @@inst = new(*args, &block) unless defined?(@@inst)
        return @@inst
      end # getSingleton()

      # method for initializing object and db connection
      def initialize(db_params, data_dir)
        begin	
          @@connection = ZabbixApi.connect(
            :url => 'http://' + db_params['ip'] + '/' + db_params['api'],
            :user => db_params['user'],
            :password => db_params['passwd']
          )
        rescue Exception => e
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
            'host' => 'server',
            'ip' => 'address',
            'hostid' => 'serverId'
          }

          avail_ident.each{ | prop, prop_val |
           
            if( params.public_send(prop_val) )
              
              hostIdentifier = params.public_send(prop_val)
              
              return self.baseQuery(params) { | query |
                query[:params]['filter'] = {
                  prop => hostIdentifier
                }
                query
              }
              
            end

          }
          
        rescue Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        end # begin
        
      end
      
      # method for getting host record for put cli action
      def putQuery(params)
        return self.connectQuery(params)
      end
      
      # method for getting host record for get cli action
      def getQuery(params)
        return self.connectQuery(params)
      end
      
      # method for getting host record for search cli action
      # contains just simple, doesn't do regex searches
      def searchQuery(params)
        
        begin

          hostIdentifier = ''
          hosts = []
          
          # these fields can be used for host record retrieval
          avail_ident = {
            'host' => 'server',
            'ip' => 'address',
            'hostid' => 'serverId'
          }

          avail_ident.each{ | prop, prop_val |
           
            if( params.public_send(prop_val) )
              
              hostIdentifier = params.public_send(prop_val)
              
              records = []
              
              records = self.baseQuery(params) { | query |
                query[:params]['filter'] = {
                  prop => hostIdentifier
                }
                query
              }
              
              hosts.push(*records)
              
            end

          }
          
        rescue Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        end # begin
        
        return hosts
        
      end
      
      # method for getting host record for script cli action
      def scriptQuery(params)
        return self.connectQuery(params)
      end
      
      # method for getting host record for cmd cli action
      def cmdQuery(params)
        return self.connectQuery(params)
      end
      
      # method for getting host record for list cli action
      def listQuery(params)
        return self.baseQuery(params) { | query |
          query
        }
      end
      
      # method for getting host record for add cli action
      def addQuery(params)
        
        begin
          
          affectedRows = 0

          groups_query = {
            :method => 'hostgroup.get',
            :params => {
              "output" => "extend",
              "filter" => {
                "name" => [
                  "Servers"
                ]
              }
            }
          }
          
          groups = @@connection.query(groups_query)
          
          if( groups.length == 0 )
            raise StandardError, "Please create group on zabbix server: Servers!"
          end

          query = {
            :method => 'host.create',
            :params => {
              "host" => params.server,
              "interfaces" => {
                "type" => 1,
                "main" => 1,
                "useip" => 1,
                "ip" => params.address,
                "dns" => "",
                "port" => "10050"
              },
              "inventory" => {
                "software" => params.desc,
                "notes" => params.sshKey
              },
              "groups" => [
                  {
                      "groupid" => groups[0]['groupid']
                  }
              ],
            }
          }
          
          hosts = @@connection.query(query)

          affectedRows = hosts['hostids'].length
          
        rescue Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        end # begin

        return affectedRows
        
      end
      
      # method for getting host record for delete cli action
      def deleteQuery(params)
        
        begin

          affectedRows = 0

          query = {
            :method => 'host.delete',
            :params => [ params.serverId ]
          }
          
          hosts = @@connection.query(query)

          affectedRows = hosts['hostids'].length
          
        rescue Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        end # begin

        return affectedRows
        
      end
      
      # method for getting host record for detail cli action
      # detail can be retrieved just by id
      def detailQuery(params)
          return self.baseQuery(params) { | query |
            query[:params]['filter'] = {
              "hostid" => params.serverId
            }
            query
          }
      end
      
      # this is basic method used for making queries to
      # zabbix api, used by other query methods
      def baseQuery(params)
        
        begin
          
          query = {
                :method => "host.get",
                :params =>  {
                    "output" => [
                        "host",
                        "name",
                        "description"
                    ],
                    "selectInventory" => [
                      "software"
                    ],
                    "selectInterfaces" => [
                      "main",
                      "ip"
                    ]
                }
          }
          
          query = yield query
          
          hosts = @@connection.query(query)
          
          hosts.each do | host |
            host_interfaces = @@connection.query(
                :method => "hostinterface.get",
                :params => {
                    "hostids" => host['hostid'], 
                    "output" => [
                        "ip"
                    ],
                    "filter" => { "main" => 1 }
                }
            )
            
            if( !host_interfaces[0].nil? )
              host['ip_address'] = host_interfaces[0]['ip']
            end
            
            if( !host['inventory'].kind_of?(Array) )
              if( host['inventory'].has_key?('software') )
                host['description'] = host['inventory']['software']
              end
            end
            
          end

        rescue Exception => e
          puts "Error occured" + e.to_s
          exit(14)
        end
        
        return hosts
        
      end
      
    end
    
  end
end
