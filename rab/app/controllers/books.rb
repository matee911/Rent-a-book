class Books < Application
  # provides :xml, :yaml, :js
  
  # before do |controller|
  #   Merb.logger.info "===== action: #{controller.action_name}"
  # end
  
  access_control(:exclude => :index) do
    allow_if "can_edit", :to => [:edit, :update], :obj => "Book"
    allow_if "can_give_back", :to => [:give_back], :obj => "Book"
    allow_if "can_add", :to => [:new, :create], :obj => "Book"
    allow_if "can_destroy", :to => [:destroy], :obj => "Book"
    allow_all :to => [:rent]
    allow_all :to => [:show]
    allow_all :to => [:hint]
  end

  def index
    page = params.delete(:page) || 1
    letter = params.delete(:letter)

    options = {:page => page, :per_page => 9, :order => 'title'}

    if !letter.nil? and ('A'..'Z').include? letter.upcase
      options[:title] = /^#{letter.upcase}/i
    elsif !letter.nil? and letter == '0':
      options[:title] = /^[0-9]/
    end
    @feed_paginator = {}
    @feed_paginator[:letter] = letter unless letter.nil?
    @books = Book.paginate(options)
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
    raise NotFound unless Book.valid_isbn?(isbn)
    render Book.hint_book(isbn).to_json, :format => :json
  end

end # Books

