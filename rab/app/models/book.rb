require 'mongo_mapper'
require 'open-uri'
require 'json'
require 'quick_magick'

class Book
  include MongoMapper::Document
  include Validatable
  
  STATUS_TYPES = {
    :na => [0, "Not available"],
    :proposition => [1, "Proposition"],
    :waiting => [2, "Waiting"],
    :available => [3, "Available"],
    :rented => [4, "Rented"]
  }
  
  validate :validate_isbn
  before_save :create_slug
  after_save :store_cover
  attr_accessor :cover_url

  key :title, String
  key :slug, String
  key :description, String
  key :isbn, String

  key :owner_uid, String
#  key :cover_url, String
  key :shop_url, String
  key :status, Integer, :numeric => true # eg. 0 - n/a, 1 - proposition, 2 - waiting, 3 - available, 4 - rented
  key :tags, Array

#  validates_numericality_of :status
  
  class << self
    def statuses_for_select
      STATUS_TYPES.values.sort_by {|arr| arr[1]}
    end
    
    def status_id(symbol)
      STATUS_TYPES[symbol][0]
    end

    def hint_book(isbn)
      isbn = isbn.gsub(/[^\d]/, "")
      doc = Nokogiri::XML(open('http://books.google.com/books/feeds/volumes?q=isbn:%s' % isbn))
      doc.remove_namespaces! # yup! i'll do
      entry = doc.xpath('/feed/entry').first
      entry_url = entry.xpath('id').text

      doc = Nokogiri::XML(open(entry_url))
      doc.remove_namespaces! # yup! i'll do

      hint = {}
      hint['title'] = doc.xpath('/entry/title[@type="text"]').text
      hint['description'] = doc.xpath('/entry/description').text
      hint['cover_url'] = doc.xpath('/entry/link[@rel="http://schemas.google.com/books/2008/thumbnail"]').attribute('href').to_s
      # doc.xpath('/entry/creator').text
      hint
    end
  end
  
  def status_readable
    type_arr = STATUS_TYPES.values.select {|arr| arr[0] == self.status}[0]
    type_arr[1] unless type_arr.nil?
  end

  def can_rent?
    self.status == STATUS_TYPES[:available][0]
  end

  IMAGES_PATH = "/assets/covers/"

  def cover
    IMAGES_PATH + "cover-%s.jpg" % self._id
  end

  def cover_thumbnail
    IMAGES_PATH + "cover-%s-t.jpg" % self._id
  end

  def has_cover?
    File.exist?(Merb.root + "/public" + self.cover_thumbnail)
  end

  def rented?
    self.status == STATUS_TYPES[:rented][0]
  end

  def rented_by
    unless self.rented?
      return nil
    end
    rh = RentHistory.all(:book_id => self._id, :order => 'from_date desc', :limit => 1).first
    rh.uid
  end

  def rented_by?(user)
    self.rented_by == user.uid
  end

  def rent(user)
    raise Exception unless self.can_rent?
    rh = RentHistory.new(:book_id => self._id, :uid => user.uid, :from_date => Time.now)
    rh.save
    self.status = STATUS_TYPES[:rented][0]
    self.save
  end

  def give_back(user)
    raise Exception unless self.rented?
    rh = RentHistory.all(:book_id => self._id, :uid => user.uid, :order => 'from_date desc', :limit => 1).first
    rh.to_date = Time.now
    rh.save
    self.status = STATUS_TYPES[:available][0]
    self.save
  end

  def history
    RentHistory.all(:book_id => self._id, :order => 'from_date desc', :limit => 10)
  end

  private
    def validate_isbn
      # isbn validators http://en.wikipedia.org/wiki/Isbn
      isbn_arr = isbn.gsub(/[^\d]/,"").split("")
      unless (isbn_arr.length == 10 || isbn_arr.length == 13)
        errors.add(:isbn, "wrong isbn number")
      else
        self.send("validate_isbn#{isbn_arr.length}", isbn_arr)
      end
    end
    
    def validate_isbn10(isbn_arr)
      check_value = isbn_arr.delete_at(-1).to_i
      checksum = 0
      isbn_arr.each_with_index { |n,i| checksum += (i+1) * n.to_i }
      errors.add(:isbn, "wrong isbn10 checksum") unless check_value == (checksum % 11)
    end
    
    def validate_isbn13(isbn_arr)
      check_value = isbn_arr.delete_at(-1).to_i
      checksum = 0
      isbn_arr.each_with_index do |n,i|
        if i%2 == 0
          checksum += n.to_i
        else
          checksum += 3 * n.to_i
        end
      end
      errors.add(:isbn, "wrong isbn13 chcecksum") unless (10 - checksum % 10) == check_value
    end
    
    def create_slug
      if self.title
        self.slug = "#{self.isbn.gsub(/[^\d]/,"")}-#{self.title.to_slug}"
      end
    end

    def store_cover
      unless self.cover_url.nil?
        body = open(self.cover_url).read
        unless File.exist?(Merb.root + "/public" + IMAGES_PATH)
          FileUtils.mkdir_p Merb.root + "/public" + IMAGES_PATH
        end
        filename_path = Merb.root + "/public" + IMAGES_PATH + "cover-%s.jpg" % self._id
        filename_thumbnail_path = Merb.root + "/public" + IMAGES_PATH + "cover-%s-t.jpg" % self._id

        file = File.new(filename_path, 'w+')
        file.puts(body)
        file.close

        img = QuickMagick::Image.read(filename_path).first
        img.resize "80x80>"
        # place for sharpening
        img.save filename_thumbnail_path
        nil
      end
    end
end
