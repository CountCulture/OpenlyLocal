ActionController::Routing::Routes.draw do |map|

  map.resources :datasets, :member => { :data => :get }

  map.resources :scrapers
  map.resources :item_scrapers, :controller => "scrapers"
  map.resources :info_scrapers, :controller => "scrapers"

  map.connect 'councils/all', :controller => "councils", :action => "index", :include_unparsed => true
  map.connect 'councils/all.xml', :controller => "councils", :action => "index", :include_unparsed => true, :format => "xml"
  map.connect 'councils/all.json', :controller => "councils", :action => "index", :include_unparsed => true, :format => "json"

  map.resources :committees, :documents, :meetings, :members, :ons_datapoints, :ons_dataset_families, :parsers, :portal_systems, :police_forces, :police_authorities, :services, :wards
  map.resources :ons_dataset_topics, :except => [:new, :destroy, :index], :member => { :populate => :post }

  map.resources :councils
  map.with_options({:path_prefix => "id", :requirements => {:redirect_from_resource => true}, :only => [:show]}) do |restype|
    restype.resources :councils
    restype.resources :members
    restype.resources :committees
    restype.resources :wards
    restype.resources :meetings
    restype.resources :police_forces
    restype.resources :police_authorities
  end

  map.connect 'wards/snac_id/:snac_id.:format', :controller => "wards", :action => "show", :requirements => { :snac_id => /\w+/ }
  map.connect 'wards/snac_id/:snac_id', :controller => "wards", :action => "show", :requirements => { :snac_id => /\w+/ }

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action
  map.connect 'info/:action', :controller => 'info'
  map.connect 'tools/:action.xml', :controller => 'tools', :format => "xml"

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  map.admin 'admin', :controller => 'admin', :action => 'index'

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "main"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
end
