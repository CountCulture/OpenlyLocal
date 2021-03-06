ActionController::Routing::Routes.draw do |map|

  map.resources :charities, :member => { :refresh => :put }

  map.resources :investigations

  map.resources :entities

  map.resources :financial_transactions

  map.connect 'companies/:jurisdiction_code/:company_number', :controller => "companies", :action => "show", :requirements => { :jurisdiction_code => /[a-z_]+/ }
  map.resources :companies, :collection => { :spending => :get }

  map.resources :suppliers
  map.resources :postcodes, :only => :show

  map.resources :scrapers, :member => { :scrape => :post }
  map.resources :item_scrapers, :controller => "scrapers", :member => { :scrape => :post }
  map.resources :info_scrapers, :controller => "scrapers", :member => { :scrape => :post }
  map.resources :csv_scrapers, :controller => "scrapers", :member => { :scrape => :post }
  map.resources :csv_parsers, :controller => "parsers"

  map.connect 'councils/all', :controller => "councils", :action => "index", :include_unparsed => true
  map.connect 'councils/all.xml', :controller => "councils", :action => "index", :include_unparsed => true, :format => "xml"
  map.connect 'councils/all.json', :controller => "councils", :action => "index", :include_unparsed => true, :format => "json"
  map.connect 'councils/open', :controller => "councils", :action => "index", :show_open_status => true
  map.connect 'councils/open.xml', :controller => "councils", :action => "index", :show_open_status => true, :format => "xml"
  map.connect 'councils/open.json', :controller => "councils", :action => "index", :show_open_status => true, :format => "json"
  map.connect 'councils/1010', :controller => "councils", :action => "index", :show_1010_status => true
  map.connect 'councils/1010.xml', :controller => "councils", :action => "index", :show_1010_status => true, :format => "xml"
  map.connect 'councils/1010.json', :controller => "councils", :action => "index", :show_1010_status => true, :format => "json"
  map.connect 'councils/:id/spending', :controller => "councils", :action => "show_spending"

  map.connect 'councils/:id/spending', :controller => "councils", :action => "show_spending"
  map.connect 'entities/:id/spending', :controller => "entities", :action => "show_spending"
  
  # map.connect 'councils/:council_id/planning_applications', :controller => "planning_applications", :action => "index"
  # map.connect 'meetings.:format', :controller => "meetings", :action => "index"
  # map.connect 'meetings', :controller => "meetings", :action => "index"
  
  map.connect 'hyperlocal_sites/custom_search.xml', :controller => "hyperlocal_sites", :action => "index", :custom_search => true, :format => "xml"
  map.resources :hyperlocal_sites, :collection => { :custom_search_results => :get, :destroy_multiple => :delete, :admin => :get }
  
  map.resources :committees, 
                :documents, 
                :hyperlocal_groups, 
                :hyperlocal_sites, 
                :members, 
                :datapoints, 
                :dataset_topic_groupings, 
                :parsers, 
                :pension_funds, 
                :portal_systems, 
                :police_forces, 
                :police_authorities, 
                :police_teams, 
                :political_parties, 
                :polls, 
                :services, 
                :twitter_accounts, 
                :user_submissions, 
                :wards, 
                :feed_entries
                
  
  map.resources :related_articles, :only => [:new, :create, :index]
  map.resources :parish_councils, :only => [:show]
  map.resources :planning_applications, :only => [:show, :index],  :collection => { :admin => :get }
  

  map.resources :councils, :collection => { :spending => :get }, :member => { :accounts => :get} do |councils|
    councils.resources :datasets, :path_prefix => 'councils/:area_id', :requirements => {:area_type => "Council"}, :only => [:show]
    councils.resources :dataset_families, :path_prefix => 'councils/:area_id', :requirements => {:area_type => "Council"}, :only => [:show]
    councils.resources :dataset_topics, :path_prefix => 'councils/:area_id', :requirements => {:area_type => "Council"}, :only => [:show]
    councils.resources :meetings, :shallow => true
    councils.resources :planning_applications, :path_prefix => 'councils/:council_id', :only => [:index]
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
    restype.resources :charities
    restype.resources :entities
    restype.resources :companies
    restype.resources :entities
    restype.resources :parish_councils
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
  map.connect 'id/councils/snac_id/:snac_id.:format', :controller => "councils", :action => "show", :requirements => { :snac_id => /\w+/, :redirect_from_resource => true }
  map.connect 'id/councils/snac_id/:snac_id', :controller => "councils", :action => "show", :requirements => { :snac_id => /\w+/, :redirect_from_resource => true }
  map.connect 'id/wards/snac_id/:snac_id.:format', :controller => "wards", :action => "show", :requirements => { :snac_id => /\w+/, :redirect_from_resource => true }
  map.connect 'id/wards/snac_id/:snac_id', :controller => "wards", :action => "show", :requirements => { :snac_id => /\w+/, :redirect_from_resource => true }
  map.connect 'parish_councils/os_id/:os_id.:format', :controller => "parish_councils", :action => "show", :requirements => { :os_id => /\d+/ }
  map.connect 'parish_councils/os_id/:os_id', :controller => "parish_councils", :action => "show", :requirements => { :os_id => /\d+/ }

  map.connect 'planning', :controller => "planning_applications", :action => "overview"
  
  map.confirm_alert_subscribers 'alert_subscribers/confirm', :controller => 'alert_subscribers', :action => 'confirm', :conditions => { :method => :get }
  map.unsubscribe_alert_subscribers 'alert_subscribers/unsubscribe', :controller => 'alert_subscribers', :action => 'unsubscribe', :conditions => { :method => :get }
  map.new_alert_subscriber 'alert_subscribers/new', :controller => 'alert_subscribers', :action => 'new', :conditions => { :method => :get }
  map.alert_subscribers 'alert_subscribers', :controller => 'alert_subscribers', :action => 'create', :conditions => { :method => :post }
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

  map.connect 'pingback/xml', :controller => 'pingback', :action => 'xml', :conditions => { :method => :post }
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
