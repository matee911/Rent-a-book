# -*- dupa: a-i-owszem -*-
class RentHistory
  include MongoMapper::Document

  key :book_id, String, :required => true
  key :uid, String, :required => true
  key :from_date, Time, :required => true
  key :to_date, Time
end
