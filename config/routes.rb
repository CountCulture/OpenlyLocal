ActionController::Routing::Routes.draw do |map|

  map.resources :investigations

  map.resources :quangos

  map.resources :financial_transactions

  map.resources :companies

  map.resources :suppliers


  map.resources :scrapers
  map.resources :item_scrapers, :controller => "scrapers"
  map.resources :info_scrapers, :controller => "scrapers"

  map.connect 'councils/all', :controller => "councils", :action => "index", :include_unparsed => true
  map.connect 'councils/all.xml', :controller => "councils", :action => "index", :include_unparsed => true, :format => "xml"
  map.connect 'councils/all.json', :controller => "councils", :action => "index", :include_unparsed => true, :format => "json"
  map.connect 'councils/open', :controller => "councils", :action => "index", :show_open_status => true
  map.connect 'councils/open.xml', :controller => "councils", :action => "index", :show_open_status => true, :format => "xml"
  map.connect 'councils/open.json', :controller => "councils", :action => "index", :show_open_status => true, :format => "json"
  map.connect 'councils/:id/spending', :controller => "councils", :action => "show_spending"
  
  # map.connect 'meetings.:format', :controller => "meetings", :action => "index"
  # map.connect 'meetings', :controller => "meetings", :action => "index"
  
  map.connect 'hyperlocal_sites/custom_search.xml', :controller => "hyperlocal_sites", :action => "index", :custom_search => true, :format => "xml"
  map.resources :hyperlocal_sites, :collection => { :custom_search_results => :get }
  
  map.resources :committees, :documents, :hyperlocal_groups, :hyperlocal_sites, :members, :datapoints, :dataset_topic_groupings, :parsers, :pension_funds, :portal_systems, :police_forces, :police_authorities, :police_teams, :political_parties, :polls, :services, :twitter_accounts, :user_submissions, :wards, :feed_entries
  
  map.resources :related_articles, :only => [:new, :create, :index]

  map.resources :councils, :collection => { :spending => :get } do |councils|
    councils.resources :datasets, :path_prefix => 'councils/:area_id', :requirements => {:area_type => "Council"}, :only => [:show]
    councils.resources :dataset_families, :path_prefix => 'councils/:area_id', :requirements => {:area_type => "Council"}, :only => [:show]
    councils.resources :dataset_topics, :path_prefix => 'councils/:area_id', :requirements => {:area_type => "Council"}, :only => [:show]
    councils.resources :meetings, :shallow => true
  end
  
  # Important: these need to go after nested resources for caching to work
  map.resources :datasets, :dataset_families, :meetings
  map.resources :dataset_topics, :except => [:new, :destroy, :index], :member => { :populate => :post }
  
  
  map.resources :wards do |wards|
    wards.resources :dataset_topics, :path_prefix => '/wards/:area_id', :requirements => {:area_type => "Ward"}, :only => [:show]
  end
  
  map.resources :output_area_classifications do |oacs|
    oacs.resources :wards, :only => [:index]
  end
  
  map.with_options({:path_prefix => "id", :requirements => {:redirect_from_resource => true}, :only => [:show]}) do |restype|
    restype.resources :councils
    restype.resources :members
    restype.resources :committees
    restype.resources :wards
    restype.resources :meetings
    restype.resources :police_forces
    restype.resources :police_authorities
  end
  
  map.connect 'areas/postcodes/:postcode', :controller => 'areas', :action => 'search'
  map.connect 'areas/postcodes/:postcode.:format', :controller => 'areas', :action => 'search'
  map.connect 'areas/search', :controller => 'areas', :action => 'search'
  
  map.connect 'wards/snac_id/:snac_id.:format', :controller => "wards", :action => "show", :requirements => { :snac_id => /\w+/ }
  map.connect 'wards/snac_id/:snac_id', :controller => "wards", :action => "show", :requirements => { :snac_id => /\w+/ }
  map.connect 'councils/snac_id/:snac_id.:format', :controller => "councils", :action => "show", :requirements => { :snac_id => /\w+/ }
  map.connect 'councils/snac_id/:snac_id', :controller => "councils", :action => "show", :requirements => { :snac_id => /\w+/ }
  map.connect 'wards/os_id/:os_id.:format', :controller => "wards", :action => "show", :requirements => { :os_id => /\d+/ }
  map.connect 'wards/os_id/:os_id', :controller => "wards", :action => "show", :requirements => { :os_id => /\d+/ }
  map.connect 'councils/os_id/:os_id.:format', :controller => "councils", :action => "show", :requirements => { :os_id => /\d+/ }
  map.connect 'councils/os_id/:os_id', :controller => "councils", :action => "show", :requirements => { :os_id => /\d+/ }

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action
  map.connect 'tools/:action.:format', :controller => 'tools'
  map.connect 'info/:action', :controller => 'info'

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  map.admin 'admin', :controller => 'admin', :action => 'index'

  map.connect 'pingback/xml', :controller => 'pingback', :action => 'xml', :method => :post
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
