# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def council_page_for(obj)
    link_to("official page", obj.url, :class => "official_page external")
  end
  
  def link_for(obj=nil, options={})
    return if obj.blank?
    freshness = options.delete(:basic) ? nil : (obj.created_at > 7.days.ago ? "new" : (obj.updated_at > 7.days.ago ? "updated" : nil) )
    css_class = ["#{obj.class.to_s.downcase}_link", options.delete(:class), freshness].compact.join(" ")
    link_to(h(obj.title), obj, { :class => css_class }.merge(options))
  end
  
  def basic_link_for(obj=nil, options={})
    link_for(obj, options.merge(:basic => true))
  end
  
  def link_to_api_url(response_type)
    link_to(response_type, params.merge(:format => response_type), :class => "api_link #{response_type}")
  end
  
  def link_to_calendar(basic_url=nil)
    basic_url ||= params
    link_to "Subscribe to this calendar", url_for(basic_url.merge(:protocol => "webcal", :only_path => false, :format => "ics")), :class => "calendar feed"
  end

  def list_all(coll=nil)
    if coll.blank?
      "<p class='no_results'>No results</p>"
    else
      coll = coll.is_a?(Array) ? coll : [coll]
      partial_name = "#{coll.first.class.table_name}/list_item"
      if partial_exists?(partial_name) 
        content_tag :ul do
          render :partial => partial_name, :collection => coll
        end
      else
        content_tag(:ul, coll.collect{ |i| (content_tag(:li, link_for(i))) }.join)
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
end
