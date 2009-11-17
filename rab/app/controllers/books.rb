class Books < Application
  # provides :xml, :yaml, :js
  
  # before do |controller|
  #   Merb.logger.info "===== action: #{controller.action_name}"
  # end
  
  # access_control(:exclude => :index) do
  #   allow_if "can_edit", :to => [:edit], :obj => "Book"
  # end

  def index
    page = params.delete(:page) || 1
    @books = Book.paginate(:page=> page, :per_page => 6, :order => 'title')
    display @books
  end

  def show(slug)
    @book = Book.find_by_slug(slug)
    raise NotFound unless @book
    display @book
  end

  def new
    only_provides :html
    @book = Book.new
    display @book
  end

  def edit(slug)
    only_provides :html
    @book = Book.find_by_slug(slug)
    raise NotFound unless @book
    display @book
  end

  def create(book)
    @book = Book.new(book)
    if @book.save
      redirect resource(@book), :message => {:notice => "Book was successfully created"}
    else
      message[:error] = "Book failed to be created"
      render :new
    end
  end

  def update(slug, book)
    @book = Book.find_by_slug(slug)
    raise NotFound unless @book
    if @book.update_attributes(book)
       redirect resource(@book)
    else
      display @book, :edit
    end
  end

  def destroy(slug)
    @book = Book.find_by_slug(slug)
    raise NotFound unless @book
    if @book.destroy
      redirect resource(:books)
    else
      raise InternalServerError
    end
  end

  def rent(slug)
    @book = Book.find_by_slug(slug)
    raise NotFound unless @book
    @book.rent(session.user)
    redirect resource(@book)
  end

  def give_back(slug)
    @book = Book.find_by_slug(slug)
    raise NotFound unless @book
    @book.give_back(session.user)
    redirect resource(@book)
  end

  # Ajax controller actions
  def hint(isbn)
    render Book.hint_book(isbn).to_json, :format => :json
  end

end # Books

