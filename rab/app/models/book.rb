# shebang
require 'open-uri'

class Book
  include MongoMapper::Document
  include Validatable
  
  ISBN10_RX = /^(?:\d[\ |-]?){9}[\d|X]$/
  ISBN13_RX = /^(?:\d[\ |-]?){13}$/
  
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
      hint['cover_url'] = nil
      cover_node = doc.xpath('/entry/link[@rel="http://schemas.google.com/books/2008/thumbnail"]')
      if cover_node.length > 0
          hint['cover_url'] = cover_node.attribute('href').to_s
      end
      # doc.xpath('/entry/creator').text
      hint
    end
    
    def valid_isbn13?(isbn_str)
      if isbn_str.match(ISBN13_RX)
        isbn_arr = isbn_str.upcase.gsub(/\ |-/, '').split('')
        check_value = isbn_arr.pop.to_i
        checksum = 0
        isbn_arr.each_with_index do |n, i|
          m = (i % 2 == 0) ? 1 : 3
          checksum += m * n.to_i
        end
        res = (10 - (checksum % 10))
        res = 0 if res == 10

        res == check_value
      else
        false
      end
    end
    
    def valid_isbn10?(isbn_str)
      if isbn_str.match(ISBN10_RX)
        isbn_arr = isbn_str.upcase.gsub(/\ |-/, '').split('')
        check_value = isbn_arr.pop
        check_value = (check_value == 'X') ? 10 : check_value.to_i
        checksum = 0
        isbn_arr.each_with_index { |n, i| checksum += (i + 1) * n.to_i }
        (checksum % 11) == check_value
      else
        false
      end
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
    rh = RentHistory.find(:all, :book_id => self._id, :order => 'from_date desc', :limit => 1).first
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
    rh = RentHistory.find(:all, :book_id => self._id, :uid => user.uid, :order => 'from_date desc', :limit => 1).first
    rh.to_date = Time.now
    rh.save
    self.status = STATUS_TYPES[:available][0]
    self.save
  end

  def history
    RentHistory.find(:all, :book_id => self._id, :order => 'from_date desc', :limit => 10)
  end

  private
    def validate_isbn
      # isbn validators http://en.wikipedia.org/wiki/Isbn
      if isbn.match(ISBN10_RX)
        validate_isbn10
      elsif isbn.match(ISBN13_RX)
        validate_isbn13
      else
        errors.add(:isbn, "wrong isbn number")
      end
    end
    
    def validate_isbn10
      errors.add(:isbn, "wrong isbn10 checksum") unless Book.valid_isbn10?(isbn)
    end
    
    def validate_isbn13
      errors.add(:isbn, "wrong isbn13 chcecksum") unless Book.valid_isbn13?(isbn)
    end
    
    def create_slug
      if self.title
        self.slug = "#{self.isbn.gsub(/\ |-/, '')}-#{self.title.to_slug}"
      end
    end

    def store_cover
      unless self.cover_url.nil? || self.cover_url.empty?
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
