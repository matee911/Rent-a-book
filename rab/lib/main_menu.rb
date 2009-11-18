require 'builder'
module Merb
  module MenuHelper
    # helpers defined here available to all views.
    def main_menu(opts = {}, &blk)
      @main_menu = []
      instance_eval &blk
      
      ul_params = {}
      ul_params[:id] = opts[:ul_id] || "mainMenu"
      ul_params[:class] = opts[:ul_class] unless opts[:ul_class].nil?
      
      first_class = opts[:first] || "first"
      last_class = opts[:last] || "last"
      active_class = opts[:active] || "active"
      
      Builder::XmlMarkup.new.ul(ul_params) do |b|
        @main_menu.each_with_index do |menu_item, idx|
          element_opts = {}
          class_elements = []
          class_elements << first_class if idx == 0
          class_elements << last_class if idx == @main_menu.length - 1 && @main_menu.length > 1
          class_elements << active_class if menu_item[:selected]
          if class_elements.length > 0
            element_opts[:class] = class_elements.join(" ")
          end
          b.li(element_opts) do
            b.a(menu_item[:title] ,:href => menu_item[:url])
          end
        end
      end
      
    end
    
    def add_menu_item(title, _url, opts = {})
      # dobrze by bylo gdyby sie znalazlo :identify_action, :identify_by
      selected = false
      path = ""
      if _url.is_a? Hash
        path = url(_url)
        selected = _url[:controller] == controller_name
        selected = _url[:action] == action_name if opts[:identify_action]
      elsif _url.is_a? String
        path = _url
        unless opts[:identify_by].nil?
          identify_by = opts[:identify_by]
          selected = identify_by[:controller] == controller_name unless identify_by[:controller].nil?
          selected = identify_by[:action] == action_name unless identify_by[:action].nil?
        end
      end
      
      @main_menu << { :title => title, :url => path, :selected => selected }
    end
    
  end
end