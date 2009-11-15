# -*- dupa: a-i-owszem -*-
class RentHistory
  include MongoMapper::Document

  key :book_id, String, :required => true
  key :uid, String, :required => true
  key :from_date, DateTime, :required => true
  key :to_date, DateTime
end
