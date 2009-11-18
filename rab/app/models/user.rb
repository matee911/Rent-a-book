require 'auth'
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
  
  many :permissions
  
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

    def users_for_select
      User.all(:fields => %w(uid full_name), :order => 'uid').map { |u| [u.uid, u.full_name] }.insert(0, ["", "-----"])
    end
  end

  
  def history
    RentHistory.find(:all, :uid => self.uid, :order => 'from_date desc', :limit => 10)
  end

  def set_god_permissions!
    rights = [
      ["can_edit", "Book"],
      ["can_give_back", "Book"],
      ["can_add", "Book"],
      ["can_destroy", "Book"]
    ]
    rights.each do |perm_name, obj|
      self.add_permission!(perm_name, obj) unless self.has_permission?(perm_name, obj)
    end
  end

  # ACL methods
  def add_permission!(permission_name, obj = nil)
    p = Permission.build_permission(permission_name, obj)
    self.permissions << p
    self.save!
  end
  
  def has_permission?(permission_name, obj = nil)
    p = Permission.build_permission(permission_name, obj)
    permission = self.permissions.select { |perm| perm == p }[0]
    !permission.nil?
  end
  
  def remove_permission(permission_name, obj = nil)
    p = Permission.build_permission(permission_name, obj)
    permission = self.permissions.select { |perm| perm = p }[0]
    self.permissions.delete(permission)
    self.save!
  end
  
  alias_method :__old_method_missing, :method_missing
  
  def method_missing(method, *args)
    match = method.to_s.scan(/^permission_([0-9a-z_]+)\?$/)
    unless match[0].nil?
      return self.has_permission?(match[0][0], args[0])
    end
    
    return __old_method_missing(method, *args)
    
  end

  
end
