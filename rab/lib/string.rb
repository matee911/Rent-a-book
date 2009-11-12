class String
  
  @@characters_trans_table = YAML.load_file(File.join(Merb.root, 'config', 'characters_trans_table.yml')) 
  
  def to_underscored
    # by k3rni
    # magia jest taka, że |match| w bloku nie jest tym co dostaniesz po rx.match
    # tylko hujem jakimś
    # i trzeba użyć tych $1
    
    gsub(/\B([a-z])([A-Z])\B/) { |match|
      "#{$1}_#{$2.downcase}"
    }
  end
  
  def to_slug(spacer = "-")
    str = self.mb_chars.downcase
    [*str].to_a.map {|c| @@characters_trans_table[c] || c }.join.gsub(/[\W_]+/, spacer)
  end
  
  alias :slugify :to_slug
  
end
