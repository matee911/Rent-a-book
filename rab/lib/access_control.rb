module AccessControl
  class AccessDenied < Exception
  end
  
  def self.included(controller)
    controller.extend(ClassMethods)
    controller.send(:include, InstanceMethods)
  end
  
  module ClassMethods
    def access_control(opts = {}, &block)
      before(nil, opts) do |controller|
        controller.ensure_authenticated
      end
      before(nil, opts) do |controller|
        controller.instance_eval(&block)
      end
    end
  end
  
  module InstanceMethods
    def allow(permission, opts = {})
      if opts[:to].nil? || opts[:to].include?(action_name.to_sym)
        unless current_user.has_permission?(permission, opts[:obj])
          raise AccessControl::AccessDenied
        end
      end
    end
    
  end
  
  
end