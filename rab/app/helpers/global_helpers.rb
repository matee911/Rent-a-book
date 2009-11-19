module Merb
  module GlobalHelpers

    def readable_date(date)
      date.strftime_ordinalized('%b %d, %Y  %H:%M') unless date.nil?
    end

  end
end
