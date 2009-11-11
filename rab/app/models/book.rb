require 'mongo_mapper'

class Book
  include MongoMapper::Document

  key :title, String
  key :description, String
  key :status, Integer # eg. 0 - n/a, 1 - proposition, 2 - waiting, 3 - available, 4 - rented
  key :cover_url, String
  key :shop_url, String
  # tags (python, ruby, iphone, management etc.)?

#  http://github.com/jnunemaker/validatable
#  validates_presence_of :title, :status
end
