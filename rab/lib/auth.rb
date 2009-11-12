require 'net/ldap'
require 'yaml'
require 'ostruct'

module Auth
  module LDAP
    CONNECTION_KEYS = [:host, :port, :auth, :encryption]
    
    class << self
      
      def settings
        @settings ||= YAML.load_file(File.join(Merb.root, 'config', 'ldap.yml'))
      end
      
      def create_connection!
        @ldap = Net::LDAP.new({
          :port => 389,
          :auth => { :method => :simple }
        }.merge(settings[:connection]))
      end
      
      def authenticate(login, password)
        create_connection!
        @ldap.auth("#{settings[:login_attr]}=#{login},#{settings[:user_base]}", password)
        @ldap.bind # true - zalogowany / false - dupa
      end
      
      def get_user(login, password)
        user = nil
        if authenticate(login, password)
          @ldap.search(
            :base => settings[:user_base], 
            :filter => Net::LDAP::Filter.eq(settings[:login_attr], login),
            :attributes => settings[:search_attributes]
            ) do |entry|
            user = OpenStruct.new
            settings[:search_attributes].each do |search_attr|
              user.send("#{search_attr.to_underscored}=", entry.send(search_attr))
            end
          end
        end
        user
      end
      
    end
    
  end
end