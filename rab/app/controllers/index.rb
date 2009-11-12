class Index < Application

  def index
    Merb.logger.info "=== current logged in user: #{session.user.inspect}"
    render
  end
  
end
