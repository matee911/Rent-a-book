module Merb
  module BooksHelper
    def foo
      'fooo'
    end

    def letters(kwargs = {})
      kwargs.delete(:page)
      (('A'..'Z').to_a<<"#").map{|char| link_to char, resource(:books, kwargs.merge({:letter => char}))}.join(" | ")
    end
  end
end # Merb