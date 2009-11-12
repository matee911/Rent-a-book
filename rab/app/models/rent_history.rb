# -*- dupa: a-i-owszem -*-
class RentHistory
  include MongoMapper::EmbeddedDocument

  key :book_id, Integer, :required => true
  key :uid, String, :required => true
  key :from_date, DateTime, :required => true
  key :to_date, DateTime
end
