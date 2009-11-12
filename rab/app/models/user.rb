require 'auth'
require 'mongo_mapper'
# This is a default user class used to activate merb-auth.  Feel free to change from a User to 
# Some other class, or to remove it altogether.  If removed, merb-auth may not work by default.
#
# Don't forget that by default the salted_user mixin is used from merb-more
# You'll need to setup your db as per the salted_user mixin, and you'll need
# To use :password, and :password_confirmation when creating a user
#
# see merb/merb-auth/setup.rb to see how to disable the salted_user mixin
# 
# You will need to setup your database and create a user.
class User
  include MongoMapper::Document

  key :uid, String, :required => true
  key :full_name, String, :required => true
  key :mails, Array
  
  class << self
    def authenticate(login, password)
      user = Auth::LDAP.get_user(login, password)

      unless user.nil?
        @dbuser = User.find_by_uid(user.uid)
        if @dbuser.nil?
          @dbuser = User.new(:uid => user.uid)
        end
        @dbuser.full_name = user.cn
        @dbuser.mails = user.mail
        if @dbuser.save
          return @dbuser
        end
      end
      nil
    end

  end
  
  # def authenticated?(password)
  #   Auth::LDAP.authenticate(login, password)
  # end
  
end
