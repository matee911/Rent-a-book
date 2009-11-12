class Books < Application
  # provides :xml, :yaml, :js

  def index
    @books = Book.all
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
       redirect url(:controller => "books", :action => "show", :slug => @book.slug)
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

end # Books
