class Application < Merb::Controller
  include AccessControl
  
  def current_user
    @current_user ||= session.user
  end
end