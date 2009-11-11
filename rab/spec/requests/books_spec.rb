require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a book exists" do
  Book.all.destroy!
  request(resource(:books), :method => "POST", 
    :params => { :book => { :id => nil }})
end

describe "resource(:books)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:books))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of books" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a book exists" do
    before(:each) do
      @response = request(resource(:books))
    end
    
    it "has a list of books" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Book.all.destroy!
      @response = request(resource(:books), :method => "POST", 
        :params => { :book => { :id => nil }})
    end
    
    it "redirects to resource(:books)" do
      @response.should redirect_to(resource(Book.first), :message => {:notice => "book was successfully created"})
    end
    
  end
end

describe "resource(@book)" do 
  describe "a successful DELETE", :given => "a book exists" do
     before(:each) do
       @response = request(resource(Book.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:books))
     end

   end
end

describe "resource(:books, :new)" do
  before(:each) do
    @response = request(resource(:books, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@book, :edit)", :given => "a book exists" do
  before(:each) do
    @response = request(resource(Book.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@book)", :given => "a book exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Book.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @book = Book.first
      @response = request(resource(@book), :method => "PUT", 
        :params => { :book => {:id => @book.id} })
    end
  
    it "redirect to the book show action" do
      @response.should redirect_to(resource(@book))
    end
  end
  
end

