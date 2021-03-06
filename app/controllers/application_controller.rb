# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :share_this, :only => [:index, :show]
  before_filter :set_canonical_url, :only => [:show]
  before_filter :redirect_from_resource, :only => :show

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '1cb17bc5dbb37dfab5a054eb922b94b3'

  rescue_from 'ActionController::MethodNotAllowed' do |exception|
    render :file => Rails.root.join('public', '404.html'), :status => 404, :layout => false
  end

  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  # Taken from http://www.coffeepowered.net/2009/02/16/powerful-easy-dry-multi-format-rest-apis-part-2/
  # Semi overrides standard render to dry up json and xml output
  def render(opts = nil, extra_options = {}, &block) 
      if opts then 
          if opts[:to_yaml] or opts[:as_yaml] then 
              headers["Content-Type"] = "text/plain;" 
              text = nil 
              if opts[:as_yaml] then 
                  text = Hash.from_xml(opts[:as_yaml]).to_yaml 
              else 
                  text = Hash.from_xml(render_to_string(:template => opts[:to_yaml], :layout => false)).to_yaml 
              end 
              super :text => text, :layout => false 
          elsif opts[:to_json] or opts[:as_json] then 
              content = nil 
              if opts[:to_json] then 
                  content = Hash.from_xml(render_to_string(:template => opts[:to_json], :layout => false)).to_json 
              elsif opts[:as_json] then 
                  content = Hash.from_xml(opts[:as_json]).to_json 
              end 
              cbparam = params[:callback] || params[:jsonp] 
              content = "#{cbparam}(#{content})" unless cbparam.blank? 
              super :json => content, :layout => false 
          else 
              super(opts, extra_options, &block) 
          end 
      else 
          super(opts, extra_options, &block) 
      end 
  end
    
  private
  def authenticate
    authenticate_or_request_with_http_basic("TWFY_local") do |username, password|
      return false unless authenticated_users[username].first == password
      permitted_auth_level = authenticated_users[username][1]
      (permitted_auth_level == :admin) or auth_level.match(permitted_auth_level.to_s)
    end
  end
  
  def authenticated_users
    AUTHENTICATED_USERS
  end
  
  def auth_level
    controller_name
  end
  
  def enable_google_maps
    @enable_google_maps = true
  end
  
  def linked_data_available
    @linked_data_available = true
  end
  
  def redirect_from_resource
    redirect_to params.except(:redirect_from_resource), :status => 303 if params[:redirect_from_resource]
  end
  
  def set_canonical_url
    @canonical_url = true
  end
  
  def share_this
    @share_this = true
  end
  
  def show_rss_link
    @show_rss_link = true
  end

  def valid_page
    page = params[:page].to_i
    if page > 0
      page
    else
      1
    end
  end
end
