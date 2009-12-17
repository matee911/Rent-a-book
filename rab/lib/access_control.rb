module AccessControl
  class AccessDenied < Merb::ControllerExceptions::Forbidden
  end
  
  def self.included(controller)
    controller.extend(ClassMethods)
    controller.send(:include, InstanceMethods)
  end
  
  module ClassMethods
    def access_control(opts = {}, &block)
      before(nil, opts) do |controller|
        controller.ensure_authenticated
        controller.disallow_all
      end
      before(nil, opts) do |controller|
        controller.instance_eval(&block)
      end
      before(nil, opts) do |controller|
        controller.check_access
      end
    end
  end
  
  module InstanceMethods
    def allow_if(permission, opts = {})
      if opts[:to].nil? || opts[:to].include?(action_name.to_sym)
        unless current_user.has_permission?(permission, opts[:obj])
          deny_access
        else
          grant_access
        end
      end
    end
    
    def disallow_all
      @allowed ||= false
    end
    
    def allow_all(opts = {})
      if opts[:to].nil? || opts[:to].include?(action_name.to_sym)
        @allowed = true
      end
    end
    
    def deny_access
      @allowed = false unless @allowed == true
    end
    
    def grant_access
      @allowed = true
    end
    
    def check_access
      raise AccessControl::AccessDenied unless @allowed == true
    end
    
  end
  
  
end