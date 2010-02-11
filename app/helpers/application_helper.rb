# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Generates an attribute block
  def attribute_tag(attrib_name=nil, attrib_value=nil, options={}, &block)
    text = options[:text]||attrib_name.to_s.titleize
    if block_given?
      concat("<dt class=\"#{attrib_name}\">#{text}</dt> <dd>#{capture(&block)}</dd>")
    elsif !attrib_value.blank?
      "<dt class=\"#{attrib_name}\">#{text}</dt> <dd>#{attrib_value}</dd>"
    end
  end

  def council_page_for(obj, options={})
    return if obj.url.blank?
    link_to("official page", obj.url, {:class => "official_page external"}.merge(options))
  end

  def link_for(obj=nil, options={})
    return if obj.blank?
    status = obj.respond_to?(:status) ? obj.status : nil
    freshness = options[:basic] ? nil : (obj.created_at&&(obj.created_at > 7.days.ago) ? "new" : (obj.updated_at&&(obj.updated_at > 7.days.ago) ? "updated" : nil) )
    css_class = [freshness, status, options[:class]].compact
    text = options[:extended]&&obj.respond_to?(:extended_title)&&obj.extended_title
    (freshness&&image_tag("#{freshness}_flash.gif", :alt => freshness, :class => "icon")).to_s + basic_link_for(obj, { :text => text, :class => css_class }.merge(options.except(:basic, :extended, :class)))
  end

  def basic_link_for(obj=nil, options={})
    return if obj.blank?
    css_class = ["#{obj.class.to_s.downcase}_link", options[:class]].flatten.compact.join(" ")
    text = options[:text] || obj.title
    obj.new_record? ? h(text) : link_to(h(text), obj, options.except(:text).merge({ :class => css_class }))
  end
  
  def breadcrumbs(obj_arr=nil)
    return if obj_arr.blank?
    content_tag(:span, obj_arr.collect{ |o| basic_link_for(o) }.join(" > "), :class => "breadcrumbs")
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
  
  def twitter_link_for(twitter_account=nil, options={})
    return if twitter_account.blank?
    options[:short] ? link_to(image_tag("twitter_icon.png", :alt => "twitter feed for #{twitter_account}"), "http://twitter.com/#{twitter_account}") : 
                      link_to("Twitter", "http://twitter.com/#{twitter_account}", :class => "twitter feed", :title => "twitter feed for #{twitter_account}")
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

  def resource_uri_for(obj)
    url_for(:id => obj.id, :only_path => false, :action => "show", :controller => obj.class.table_name, :redirect_from_resource => true)
  end
  
  def formatted_datapoint_value(datapoint)
    return if datapoint.value.blank?
    if datapoint.muid_type == "Pounds Sterling"
      "£#{number_with_delimiter(datapoint.value.to_i)}"
    elsif datapoint.value.to_i >= 1000
      number_with_delimiter(datapoint.value)
    else
      datapoint.muid_format ? sprintf(datapoint.muid_format, datapoint.value) : datapoint.value
    end
  end

  # Outputs statistics table. Expects to be passed an array of datapoints and various options
  def statistics_table(datapoints=nil, options={})
    return if datapoints.blank?
    max_value = datapoints.collect{|dp| dp.value.to_f }.max
    total = BareDatapoint.new(:value => datapoints.inject(0.0){|sum, dp| sum + dp.value.to_f }, :muid_format => datapoints.first.muid_format, :muid_type => datapoints.first.muid_type)
    content = []
    show_more_info = options[:show_more_info]
    bg_pos_multiplier = show_more_info ? 7.1 : 7.7 #width of description cell is either 700px or 760px + 5px padding either side
    
    content << content_tag(:caption, options[:caption])
    # header row
    content << content_tag(:tr) do
      content_tag(:th, options[:description].to_s.titleize) + 
        content_tag(:th, 'Value', :class => "value") +
        (show_more_info&&content_tag(:th, 'More info', :class => 'more_info')).to_s
    end 
    # table body
    content << datapoints.collect do |datapoint|
      css_class = (datapoint == options[:selected] ? 'selected datapoint' : 'datapoint')
      bg_position = (100.0/max_value)*bg_pos_multiplier*datapoint.value.to_f
      content_tag :tr, :class => css_class do          
        content_tag(:td, basic_link_for(datapoint.send(options[:description])), :class => 'description', :style => "background-position:#{bg_position}px") + 
          content_tag(:td, formatted_datapoint_value(datapoint), :class => 'value') + 
          (show_more_info&&content_tag(:td, link_to(image_tag('inspect.gif', :alt => 'See breakdown of this figure', :class => 'icon'), [datapoint.area, datapoint.subject].compact), :class => 'more_info')).to_s
      end
    end
    # optional total
    if options[:show_total]
      content << content_tag(:tr, :class => "total") do
        content_tag(:td, "Total", :class => "description") +
          content_tag(:td, formatted_datapoint_value(total), :class => "value") + 
          (show_more_info&&content_tag(:td)).to_s
      end
    end
    
    content_tag(:table, :class => 'datapoints statistics') { content.flatten.compact } +
      content_tag(:div, "<strong>Source</strong> #{breadcrumbs(options[:source])}", :class => "source attribution")
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

  def help_link_to(url)
    return if url.blank?
    link_to(image_tag("help.png"), url, :class => "help", :alt => "help")
  end  

  def wikipedia_link_for(subject, options={})
    return if subject.blank?
    link_to(subject, options[:url]||"http://en.wikipedia.org/wiki/#{subject.gsub(' ', '_')}", :class => "wikipedia_link external", :title => "Wikipedia page for '#{subject}'")
  end
end
