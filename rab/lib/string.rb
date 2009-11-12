class String
  def to_underscored
    # by k3rni
    # magia jest taka, że |match| w bloku nie jest tym co dostaniesz po rx.match
    # tylko hujem jakimś
    # i trzeba użyć tych $1
    
    gsub(/\B([a-z])([A-Z])\B/) { |match|
      "#{$1}_#{$2.downcase}"
    }
  end
end