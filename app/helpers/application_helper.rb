# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def council_page_for(obj, options={})
    return if obj.url.blank?
    link_to("official page", obj.url, {:class => "official_page external"}.merge(options))
  end
  
  def link_for(obj=nil, options={})
    return if obj.blank?
    freshness = options[:basic] ? nil : (obj.created_at > 7.days.ago ? "new" : (obj.updated_at > 7.days.ago ? "updated" : nil) )
    text = options[:extended]&&obj.respond_to?(:extended_title)&&obj.extended_title
    basic_link_for(obj, { :freshness => freshness, :text => text }.merge(options.except(:basic, :extended)))
  end
  
  def basic_link_for(obj=nil, options={})
    return if obj.blank?
    css_class = ["#{obj.class.to_s.downcase}_link", options.delete(:freshness), options[:class]].compact.join(" ")
    text = options[:text] || obj.title
    obj.new_record? ? h(text) : link_to(h(text), obj, options.except(:text).merge({ :class => css_class }))
  end
  
  # http://googlewebmastercentral.blogspot.com/2009/02/specify-your-canonical.htm
  def canonical_link_tag
    return unless @canonical_url
    return tag(:link, :rel => :canonical, :href => @canonical_url) unless @canonical_url == true # then canonical_url has been set explicitly 
    resource_name = controller.controller_name.gsub(/s/,'')
    resource = instance_variable_get("@#{resource_name}")
    @canonical_url = tag(:link, :rel => :canonical, :href => send("#{resource_name}_path", resource)) if resource
  end

  def extended_link_for(obj=nil, options={})
    link_for(obj, options.merge(:extended => true))
  end
  
  def link_to_api_url(response_type)
    params[:id] = params[:id].to_i if params[:id] # if we've got an id, clean it up
    link_to(response_type, params.merge(:format => response_type), :class => "api_link #{response_type}")
  end
  
  def link_to_calendar(basic_url=nil)
    basic_url ||= params
    link_to "Subscribe to this calendar", url_for(basic_url.merge(:protocol => "webcal", :only_path => false, :format => "ics")), :class => "calendar feed"
  end

  def list_all(coll=nil, options={})
    if coll.blank?
      "<p class='no_results'>No results</p>"
    else
      coll = coll.is_a?(Array) ? coll : [coll]
      partial_name = "#{coll.first.class.table_name}/list_item"
      if partial_exists?(partial_name) 
        content_tag :ul do
          render :partial => partial_name, :collection => coll, :locals => { :list_options => options }
        end
      else
        content_tag(:ul, coll.collect{ |i| (content_tag(:li, link_for(i,options))) }.join)
      end
    end
  end
  
  def timestamp_data_for(obj)
    content_tag(:p, "Last updated #{obj.updated_at.to_s(:short)} (#{time_ago_in_words(obj.updated_at)} ago)", :class => "attribution")
  end
  
  # quick n dirty way of seeing if partial exists
  def partial_exists?(partial_name)
    partial_name, ctrler_name = partial_name.split('/', 2).reverse
    File.exists? File.join(RAILS_ROOT, 'app/views/', ctrler_name || '' ,"_#{partial_name}.html.erb")
  end
  
  def rdfa_vocab_url
    url_for(:controller => "info", :action => "vocab", :only_path => false)
  end
  
  def wikipedia_help_link(wiki_url)
    return if wiki_url.blank?
    link_to(image_tag("help.png"), wiki_url, :class => "help", :alt => "help")
  end
end
