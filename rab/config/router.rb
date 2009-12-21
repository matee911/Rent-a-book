# Merb::Router is the request routing mapper for the merb framework.
#
# You can route a specific URL to a controller / action pair:
#
#   match("/contact").
#     to(:controller => "info", :action => "contact")
#
# You can define placeholder parts of the url with the :symbol notation. These
# placeholders will be available in the params hash of your controllers. For example:
#
#   match("/books/:book_id/:action").
#     to(:controller => "books")
#   
# Or, use placeholders in the "to" results for more complicated routing, e.g.:
#
#   match("/admin/:module/:controller/:action/:id").
#     to(:controller => ":module/:controller")
#
# You can specify conditions on the placeholder by passing a hash as the second
# argument of "match"
#
#   match("/registration/:course_name", :course_name => /^[a-z]{3,5}-\d{5}$/).
#     to(:controller => "registration")
#
# You can also use regular expressions, deferred routes, and many other options.
# See merb/specs/merb/router.rb for a fairly complete usage sample.

UID_RX = /^[a-z0-9\.]+$/i
SLUG_RX = /^[a-zA-Z0-9\-]+$/
ISBN_RX = /^[\d\-]+$/

Merb.logger.info("Compiling routes...")
Merb::Router.prepare do
  # RESTful routes
  resources :books, :identify => :slug
  resources :users, :identify => :uid, :uid => UID_RX
  
  # Adds the required routes for merb-auth using the password slice
  slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")
  
  authenticate do
    match("/").to(:controller => 'books')
  end

  match("/history").to(:controller => "books", :action => "history").name(:history)
  match("/users/:uid", :uid => UID_RX).to(:controller => "users", :action => "show").name(:show_user)
  match("/books/:slug/rent", :slug => SLUG_RX).to(:controller => "books", :action => "rent").name(:rent_book)
  match("/books/:slug/give_back", :slug => SLUG_RX).to(:controller => "books", :action => "give_back").name(:give_back_book)
  match("/ajax/books/hint/:isbn", :isbn => ISBN_RX).to(:controller => "books", :action => "hint")

  # This is the default route for /:controller/:action/:id
  # This is fine for most cases.  If you're heavily using resource-based
  # routes, you may want to comment/remove this line to prevent
  # clients from calling your create or destroy actions with a GET
  default_routes

end
