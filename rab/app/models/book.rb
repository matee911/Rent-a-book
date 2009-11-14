require 'mongo_mapper'
require 'net/http'
require 'uri'
require 'open-uri'
require 'json'

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

  IMAGES_PATH = "/assets/covers/"

  def cover
    ext = 'jpg'
    IMAGES_PATH + "cover-%s.%s" % [self._id, ext]
  end

  def has_cover?
    File.exist?(Merb.root + "/public" + self.cover)
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
        body = Net::HTTP::get(URI.parse(self.cover_url))
        unless File.exist?(Merb.root + "/public" + IMAGES_PATH)
          FileUtils.mkdir_p Merb.root + "/public" + IMAGES_PATH
        end
        ext = 'jpg'
        filename = Merb.root + "/public" + IMAGES_PATH + "cover-%s.%s" % [self._id, ext]
        file = File.new(filename, 'w+')
        file.puts(body)
        nil
      end
    end

#  http://github.com/jnunemaker/validatable
#  validates_presence_of :title, :status
end
