class Index < Application

  def index
    Merb.logger.info "=== current logged in user: #{session.user.inspect}"
    render
  end
  
  def check
    @book = Book.first
    render @book.title, :format => :text
  end
  
end
