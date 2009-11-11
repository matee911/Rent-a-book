require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/index" do
  before(:each) do
    @response = request("/index")
  end
end