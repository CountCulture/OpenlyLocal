require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  context "attribute_tag helper method" do

    should "return nil by default" do
      assert_nil attribute_tag
    end

    should "return div tag using key as attrib name and value as value" do
      assert_dom_equal "<dt>Foo Bar</dt> <dd class=\"foo_bar\">some value</dd>", attribute_tag(:foo_bar, "some value")
    end

    should "use supplied text for name if given" do
      assert_dom_equal "<dt>Different name</dt> <dd class=\"foo_bar\">some value</dd>", attribute_tag(:foo_bar, "some value", :text => "Different name")
    end

    should "add given class to dd element" do
      assert_dom_equal "<dt>Different name</dt> <dd class=\"foo_bar baz\">some value</dd>", attribute_tag(:foo_bar, "some value", :text => "Different name", :class => 'baz')
    end

    should "add given rel to dd" do
      assert_dom_equal "<dt>Different name</dt> <dd class=\"foo_bar\" rel=\"foo bar\">some value</dd>", attribute_tag(:foo_bar, "some value", :text => "Different name", :rel => 'foo bar')
    end

    should "return nil if value is nil" do
      assert_nil attribute_tag(:foo_bar, nil)
    end

    should "return nil if value is blank" do
      assert_nil attribute_tag(:foo_bar, "")
    end
  end

  context "link_for helper method" do

    should "return nil by default" do
      assert_nil link_for
    end

    should "return link for item with object title for link text" do
      obj = stale_factory_object(:committee) # poss better way of testing this. obj can be any ActiveRecord obj
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), link_for(obj)
    end

    should "use underscore version of object class for link class" do
      obj = stale_factory_object(:hyperlocal_site) # poss better way of testing this. obj can be any ActiveRecord obj
      assert_dom_equal link_to(obj.title, obj, :class => "hyperlocal_site_link"), link_for(obj)
    end

    should "escape object's title" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link"), link_for(obj)
    end

    should "pass on options" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :foo => "bar", :class => "committee_link"), link_for(obj, :foo => "bar")
    end

    should "leave options hash untouched" do
      obj = stale_factory_object(:committee)
      h = {:text => "bar", :class => "foo", :extended => true, :basic => true}
      old_h = h.clone
      link_for(obj, h)
      assert_equal old_h, h
    end

    should "add given class to object class" do
      obj = stale_factory_object(:committee, :title => "something & nothing" )
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link bar"), link_for(obj, :class => "bar")
    end

    should "add object's status of object to class" do
      obj = stale_factory_object(:committee, :title => "something & nothing" )
      obj.stubs(:status).returns("foostatus")
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link foostatus bar"), link_for(obj, :class => "bar")
    end

    should "not fail if object doesn't respond_to? status" do
      self.stubs(:mocha_mock_path).returns('/')
      obj1 = stub_everything(:title => 'object') # so will return false to respond_to? and new_record? methods
      obj1.stubs(:respond_to?).with(:status).returns(false)
      obj1.stubs(:status).raises(NoMethodError) # shouldn't be called
      assert_nothing_raised(Exception) {link_for(obj1, :class => "bar")}
    end

    should "add 'new' class and flash if it has recently been created" do
      obj = Factory(:committee)
      assert_dom_equal image_tag("new_flash.gif", :alt => "new", :class => "icon") + link_to(obj.title, obj, :class => "committee_link new"), link_for(obj)
    end

    should "add 'updated' class and flash if it is not new but has recently been updated" do
      obj = Factory(:committee)
      obj.stubs(:created_at => 8.days.ago)
      assert_dom_equal image_tag("updated_flash.gif", :alt => "updated", :class => "icon") + link_to(obj.title, obj, :class => "committee_link updated"), link_for(obj)
    end

    should "add new class and flash if it has recently been created as well as given class" do
      obj = Factory(:committee)
      assert_dom_equal image_tag("new_flash.gif", :alt => "new", :class => "icon") + link_to(obj.title, obj, :class => "committee_link new foo"), link_for(obj, :class => "foo")
    end

    should "return basic_link if it is requested" do
      obj = Factory(:committee)

      assert_dom_equal basic_link_for(obj), link_for(obj, :basic => true)
    end

    should "return extended_link if it is requested" do
      obj = Factory(:committee)
      obj.stubs(:extended_title => "some extended title")

      assert_dom_equal extended_link_for(obj), link_for(obj, :extended => true)
    end

    should "use given text for link in preference to object title" do
      obj = stale_factory_object(:committee)
      assert_dom_equal link_to("Some other text", obj, :class => "committee_link"), link_for(obj, :text => "Some other text")
    end

  end

  context "basic_link_for helper method" do

    should "return nil by default" do
      assert_nil basic_link_for
    end

    should "return nil by if blank" do
      assert_nil basic_link_for("")
    end

    should "return show as plain text if object is new" do
      assert_equal "new committee", basic_link_for(Committee.new(:title => "new committee"))
    end

    should "return empty string if new object's title is nil" do
      assert_equal "", basic_link_for( Committee.new)
    end

    should "escape new object's title" do
      assert_equal h("something & nothing... which <needs> escaping"), basic_link_for(Committee.new(:title => "something & nothing... which <needs> escaping"))
    end

    # should "return nil if object's title is nil" do
    #   assert_nil basic_link_for Committee.new
    # end

    # should "return nil if object's title is nil" do
    #   assert_nil basic_link_for Committee.new
    # end

    should "return link for item with object title for link text" do
      obj = stale_factory_object(:committee) # poss better way of testing this. obj can be any ActiveRecord obj
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), basic_link_for(obj)
    end

    should "leave options hash untouched" do
      obj = stale_factory_object(:committee)
      h = { :text => "bar", :class => "foo" }
      old_h = h.clone
      basic_link_for(obj, h)
      assert_equal old_h, h
    end

    should "escape object's title" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link"), basic_link_for(obj)
    end

    should "pass on options" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :foo => "bar", :class => "committee_link"), basic_link_for(obj, :foo => "bar")
    end

    should "add given class to object class" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link bar"), basic_link_for(obj, :class => "bar")
    end

    should "not add new class if it has recently been created" do
      obj = Factory(:committee)
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), basic_link_for(obj)
    end

    should "not add updated class if it is not new but has recently been updated" do
      obj = Factory(:committee)
      obj.stubs(:created_at => 8.days.ago)
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), basic_link_for(obj)
    end
  end

  context "extended_link_for helper method" do

    should "return nil by default" do
      assert_nil extended_link_for
    end

    should "return link_for object by default" do
      obj = stale_factory_object(:committee) # poss better way of testing this. obj can be any ActiveRecord obj
      assert_dom_equal link_for(obj), extended_link_for(obj)
    end

    should "pass options to link_for" do
      obj = stale_factory_object(:committee)
      assert_dom_equal link_for(obj, :foo => "bar"), extended_link_for(obj, :foo => "bar")
    end

    should "leave options hash untouched" do
      obj = stale_factory_object(:committee)
      h = {:text => "bar", :class => "foo"}
      old_h = h.dup
      extended_link_for(obj, h)
      assert_equal old_h, h
    end

    should "use object's extended title if it exists" do
      obj = stale_factory_object(:committee)
      obj.stubs(:extended_title => "some extended title")
      assert_dom_equal link_for(obj, :text => "some extended title"), extended_link_for(obj)
    end

    should "use given text in preference to object's extended title" do
      obj = stale_factory_object(:committee)
      obj.stubs(:extended_title => "some extended title")
      assert_dom_equal link_for(obj, :text => "some other text"), extended_link_for(obj, :text => "some other text")
    end
  end

  context "council_page_for helper method" do

    should "return link based on url" do
      obj = stub(:url => "http://somecouncil/meeting")
      assert_dom_equal link_to("official page", "http://somecouncil/meeting", :class => "official_page external url"), council_page_for(obj)
    end

    should "return nil if url nil" do
      obj = stub(:url => nil)
      assert_nil council_page_for(obj)
    end

    should "use options when constructing link" do
      obj = stub(:url => "http://somecouncil/meeting")
      assert_dom_equal link_to("official page", "http://somecouncil/meeting", :class => "official_page external url", :foo => "bar"), council_page_for(obj, :foo => "bar")
    end

  end

  context "link_to_api_url" do
    setup do
      @controller = TestController.new
      self.stubs(:params).returns(:controller => "councils", :action => "index")
    end

    should "should return xml link when xml requested" do
      assert_equal link_to("xml", { :controller => "councils", :action => "index", :format => "xml" }, :class => "api_link xml"), link_to_api_url("xml")
    end

    should "should return js link when json requested" do
      assert_equal link_to("json", { :controller => "councils", :action => "index", :format => "json" }, :class => "api_link json"), link_to_api_url("json")
    end

    should "should ignore submit params when constructing" do
      self.stubs(:params).returns(:controller => "councils", :action => "index", :submit => 'Search+by+postcode')
      assert_equal link_to("xml", { :controller => "councils", :action => "index", :format => "xml" }, :class => "api_link xml"), link_to_api_url("xml")
    end

    should "should use id rather than to_param in url js link when json requested" do
      resource = Factory(:member)
      self.stubs(:params).returns(:controller => "members", :action => "show", :id => resource.to_param)
      assert_equal link_to("json", { :controller => "members", :action => "show", :format => "json", :id => resource.id }, :class => "api_link json"), link_to_api_url("json")
    end

  end

  context "twitter_link_for helper method" do

    should "return nil by default" do
      assert_nil twitter_link_for
      assert_nil twitter_link_for("")
    end

    should "return link for twitter_account" do
      assert_dom_equal link_to("Twitter", "http://twitter.com/foo", :class => "twitter feed url", :title => "Twitter page for foo", :rel => "me tag"), twitter_link_for("foo")
    end

    should "return just twitter image tage instead of text if short requested" do
      assert_dom_equal link_to(image_tag("twitter_icon.png", :alt => 'Twitter page for foo'), 'http://twitter.com/foo', :class => 'twitter', :title => 'Twitter page for foo'), twitter_link_for("foo", :short => true)
    end
  end
  
  context "facebook_link_for helper method" do

    should "return nil by default" do
      assert_nil facebook_link_for
      assert_nil facebook_link_for("")
    end

    should "return link for facebook_account" do
      assert_dom_equal link_to("Facebook", "http://facebook.com/foo", :class => "facebook feed url", :title => "Facebook page for foo", :rel => "me tag"), facebook_link_for("foo")
    end

    should "return just facebook_icon image tag instead of text if short requested" do
      assert_dom_equal link_to(image_tag("facebook_icon.png", :alt => "Facebook page for foo"), "http://facebook.com/foo", :class => 'facebook', :title => 'Facebook page for foo'), facebook_link_for("foo", :short => true)
    end
  end
  
  context "list_all helper method" do
    setup do
      @obj1 = Factory(:committee )
      @obj2 = Factory(:another_council)
    end

    should "return message if no object given" do
      assert_dom_equal "<p class='no_results'>No results</p>", list_all
    end

    should "return message if empty_array given" do
      assert_dom_equal "<p class='no_results'>No results</p>", list_all([])
    end

    should "return message if nil given" do
      assert_dom_equal "<p class='no_results'>No results</p>", list_all(nil)
    end

    should "check to see if list_item partial exists for item" do
      self.expects(:partial_exists?).with('committees/list_item')
      list_all(@obj1)
    end

    context "when no list_item partial exists for given item" do
      setup do
        self.stubs(:partial_exists?)
      end

      should "return unordered list of objects using link_for helper method" do
        assert_dom_equal "<ul><li>#{link_for(@obj1)}</li><li>#{link_for(@obj2)}</li></ul>", list_all([@obj1,@obj2])
      end

      should "return unordered list of single object" do
        assert_dom_equal "<ul><li>#{link_for(@obj1)}</li></ul>", list_all(@obj1)
      end

      should "pass on options to link if given" do
        assert_dom_equal "<ul><li>#{link_for(@obj1, :foo => "bar")}</li></ul>", list_all(@obj1, :foo => "bar")
      end

    end

    context "when list_item partial exists for given item" do

      should "render using partial" do
        # need to figure out way of testing this
      end
    end

  end

  context "partial_exists helper method" do
    should "return false by default" do
      assert !partial_exists?("foo")
    end

    should "return true if partial exists" do
      assert partial_exists?("shared/footer")
    end
  end

  context "link_to_calendar helper method" do
    setup do
      @controller = TestController.new
      self.stubs(:params).returns(:controller => "meetings", :action => "index", :foo => "bar")
    end

    should "return link to current page with calendar params added" do
      assert_equal link_to("Subscribe to this calendar", { :controller => "meetings",
                                                           :action => "index",
                                                           :foo => "bar",
                                                           :protocol => "webcal",
                                                           :only_path => false,
                                                           :format => "ics" }, :class => "calendar feed"),
                      link_to_calendar
    end

    should "return link to given page with calendar params added" do
      assert_equal link_to("Subscribe to this calendar", { :controller => "committees",
                                                           :action => "show",
                                                           :id => 1,
                                                           :protocol => "webcal",
                                                           :only_path => false,
                                                           :format => "ics" }, :class => "calendar feed"),
                      link_to_calendar({:controller => "committees", :action => "show", :id => 1})
    end
  end

  context "canonical_link_tag helper method" do

    should "return nil by default" do
      assert_nil canonical_link_tag
    end

    should "return link to canonical_url if set" do
      self.instance_variable_set(:@canonical_url, "/foo/bar")
      assert_dom_equal tag(:link, :rel => :canonical, :href => "/foo/bar"), canonical_link_tag
    end

    should "return link to calculated canonical_url if canonical_url IS true" do
      member = Factory(:member)
      self.stubs(:controller).returns(stub(:controller_name => "members"))
      self.instance_variable_set(:@canonical_url, true)
      self.instance_variable_set(:@member, member)
      assert_dom_equal tag(:link, :rel => :canonical, :href => "/members/#{member.to_param}"), canonical_link_tag
    end

    should "return nil if canonical_url IS true but controller doesn't have instance variable for resource" do
      member = Factory(:member)
      self.stubs(:controller).returns(stub(:controller_name => "members"))
      self.instance_variable_set(:@canonical_url, true)
      assert_nil canonical_link_tag
    end

  end

  context "timestamp_data_for helper method" do
    setup do
      @last_updated = 2.hours.ago
      @obj = stub(:updated_at => @last_updated)
    end
    should "return details of when updated" do
      assert_dom_equal content_tag(:p, "Last updated #{@last_updated.to_s(:short)} (#{time_ago_in_words(@last_updated)} ago)", :class => "attribution"), timestamp_data_for(@obj)
    end
  end

  context "help_link_to helper method" do
    should "return nil by default" do
      assert_nil help_link_to(nil)
    end

    should "return link to url using help icon" do
      assert_equal link_to(image_tag("help.png", :alt => "help"), "http://en.wikipedia.org/wiki/London_borough", :class => "help"), help_link_to("http://en.wikipedia.org/wiki/London_borough")
    end
  end

  context "wikipedia_link_for helper method" do
    should "return nil by default" do
      assert_nil wikipedia_link_for(nil)
    end

    should "return link to wikipedia_page" do
      assert_equal link_to("Foo Bar", "http://en.wikipedia.org/wiki/Foo_Bar", :class => "wikipedia_link external", :title => "Wikipedia page for 'Foo Bar'"), wikipedia_link_for("Foo Bar")
    end

    should "return link to wikipedia_page using URL given" do
      assert_equal link_to("Foo Bar", "http://en.wikipedia.org/wiki/Bar_Foo_Baz", :class => "wikipedia_link external", :title => "Wikipedia page for 'Foo Bar'"), wikipedia_link_for("Foo Bar", :url => "http://en.wikipedia.org/wiki/Bar_Foo_Baz")
    end
  end
  
  context 'licence_link_for helper method' do
    should "return nil by default" do
      assert_nil licence_link_for(nil)
    end

    should "return link to licence page" do
      assert_equal link_to(Licences['CC0'].first, Licences['CC0'].last, :class => "licence_link external", :title => "Licence details for #{Licences['CC0'].first}"), licence_link_for('CC0')
    end
  end

  context "resource_uri_for helper method" do

    should "return url_for object with :redirect_from_resource flag set and only using id" do
      # @obj = Factory(:committee )
      # assert_equal "http://test.com/id/committees/#{@obj.id}", resource_uri_for(@obj)
    end
  end
  
  context "breadcrumbs helper method" do
    setup do
      @obj1 = Factory(:council)
      @obj2 = Factory(:committee, :council => @obj1)
    end
    
    should "show basic link to given item in breadcrumb div" do  
      assert_equal content_tag(:span, basic_link_for(@obj1), :class => "breadcrumbs"), breadcrumbs([@obj1])
    end
    
    should "return nil if no items basic links to given item" do  
      assert_nil breadcrumbs([])
      assert_nil breadcrumbs(nil)
    end
    
    should "show basic links to items separated by '>'" do
      assert_equal content_tag(:span, "#{basic_link_for @obj2} > #{basic_link_for @obj1}", :class => "breadcrumbs"), breadcrumbs([@obj2, @obj1])
    end
    
    should "show strings when objects" do
      assert_equal content_tag(:span, "#{basic_link_for @obj2} > foo", :class => "breadcrumbs"), breadcrumbs([@obj2, "foo"])
    end
    
  end
  
  context "basic_table helper method" do
    setup do
      @headings = %w(bar baz)
      @data = [[4,3], ["a", "b"], [nil, "d"]]
      @basic_table_params = { :caption => "Foo Data", :headings => @headings, :data => @data }
      @table = basic_table(@basic_table_params)
      @parsed_table = Hpricot(@table)
    end
    
    should "return table" do
      assert @parsed_table.at('table')
    end
    
    should "give use given caption" do
      assert_equal "Foo Data", @parsed_table.at('table caption').inner_text
    end
    
    should "use given headings" do
      assert @parsed_table.at('table th[text()=bar]')
      assert @parsed_table.at('table th[text()=baz]')
    end
    
    should "user given data" do
      assert_equal 3, @parsed_table.search('table tr[td]').size
    end
    
    should "not show link to more by default" do
      assert !@parsed_table.at('a.more_info')
    end
    
    should "show link to more if given" do
      assert Hpricot(basic_table(@basic_table_params.merge(:more_info_url => '/bar'))).at('.more_info a')
    end
    
    should "use more info url in caption when link given" do
      assert Hpricot(basic_table(@basic_table_params.merge(:more_info_url => '/bar'))).at('caption a')
    end
    
    should "use given classes on table headers and rows" do
      parsed_table = Hpricot(basic_table(@basic_table_params.merge(:classes => ['foo','bar'])))
      assert_equal ['foo','bar'], parsed_table.search('th').collect{|th| th[:class]}
      assert parsed_table.search('td').in_groups_of(2).all?{ |g| g.collect{|td| td[:class]} == ['foo','bar']}
    end
    
  end
  
  context "the formatted_datapoint_value helper method" do
    should "return nil if value blank" do
      assert_nil formatted_datapoint_value(stub_everything)
      assert_nil formatted_datapoint_value(stub_everything(:value => ""))
    end

    should "format value depending on muid by default" do
      assert_equal '345', formatted_datapoint_value(stub_everything(:value => 345)).to_s #we only care about how it looks as a string
      assert_equal '£345', formatted_datapoint_value(stub_everything(:value => 345, :muid_format => "£%d"))
      assert_equal '24.6%', formatted_datapoint_value(stub_everything(:value => 24.62, :muid_format => "%.1f%"))
      assert_equal '34,567', formatted_datapoint_value(stub_everything(:value => 34567))
    end
    
    should "format with pound sign and delimiter if muid_type is Pounds Sterling" do
      assert_equal '£345', formatted_datapoint_value(stub_everything(:value => 345, :muid_type => "Pounds Sterling")).to_s #we only care about how it looks as a string
      assert_equal '£345', formatted_datapoint_value(stub_everything(:value => 345.0, :muid_type => "Pounds Sterling")).to_s #we only care about how it looks as a string
      assert_equal '£345', formatted_datapoint_value(stub_everything(:value => 345, :muid_format => "%.1f%", :muid_type => "Pounds Sterling")).to_s
      assert_equal '£0', formatted_datapoint_value(stub_everything(:value => 0, :muid_format => "%.1f%", :muid_type => "Pounds Sterling")).to_s
      assert_equal '£345,123,456', formatted_datapoint_value(stub_everything(:value => 345123456, :muid_type => "Pounds Sterling")).to_s
      assert_equal '£345,123,456', formatted_datapoint_value(stub_everything(:value => 345123456.0, :muid_type => "Pounds Sterling")).to_s
      assert_nil formatted_datapoint_value(stub_everything(:value => "", :muid_type => "Pounds Sterling"))
    end
  end

  context "statistics_table helper method" do
    setup do
      @area = Factory(:council, :name => "Council with statistics")
      @subject_1 = Factory(:dataset_family)
      @subject_2 = Factory(:dataset_family)
      @dummy_datapoint_1 = BareDatapoint.new(:value => 1234.0, :area => @area, :subject => @subject_1)
      @dummy_datapoint_2 = BareDatapoint.new(:value => 93.53, :area => @area, :subject => @subject_2, :muid_type => 'Percentage', :muid_format => "%.1f%")
      @table_options = { :description => "area", 
                        :selected => @dummy_datapoint_2, 
                        :caption => "Foo caption", 
                        :source => [@subject_1.dataset]}
      @table = parsed_stats_table([@dummy_datapoint_1, @dummy_datapoint_2], @table_options)
    end
    
    should "return nil if no datapoints" do
      assert_nil statistics_table(nil)
    end
    
    should "return nil if datapoints empty" do
      assert_nil statistics_table([])
    end
    
    should "return table of datapoints" do
      assert_equal 2, @table.search('table.statistics tr.datapoint').size
    end
    
    should "use given caption for table caption" do
      assert_equal "Foo caption", @table.at('caption').inner_text
    end
    
    should "use given source for source breadcrumbs" do
      assert_equal breadcrumbs([@subject_1.dataset]), @table.at('.breadcrumbs').to_s
    end
    
    should "show formatted_value as datapoint value" do
      assert @table.at('.datapoint td.value[text()="93.5%"]')
    end
    
    should "link to datapoint attribute given in description option for description" do
      assert_equal basic_link_for(@area), @table.at('.datapoint td.description a').to_s
    end
    
    should "show headings for table based on description option" do
      assert @table.at('table.statistics th[text()=Area]')
      assert @table.at('table.statistics th[text()=Value]') #this doesn't change
    end
    
    should "mark selected item as selected" do
      assert @table.at('tr.selected td[text()="93.5%"]')
    end
    
    should "style description background position based on value to make graph" do
      expected_position = 7.7*(100.0/@dummy_datapoint_1.value.to_f)*@dummy_datapoint_2.value.to_f #full length is 770px, scale so max value is 100%: (800/100)*(100.0/max_value)*datapoint.value.to_f
      actual_position = @table.at(".selected td.description")["style"].scan(/([\d\.]+)px/).to_s
      assert_in_delta(expected_position, actual_position, 0.1)
    end
    
    should "not show more_data column by default" do
      assert_nil @table.at('th.more_info')
      assert_nil @table.at('td.more_info')
    end
    
    should "not show total by default" do
      assert_nil @table.at('tf.total')
    end
    
    context "when requested to show total" do
      setup do
        @tt = parsed_stats_table([@dummy_datapoint_1, @dummy_datapoint_2], @table_options.merge(:show_total => true))
      end
      
      should "show total description in row with total class" do
        assert @tt.at('tr.total td.description[text()="Total"]')
      end
      
      should "show total in footer column" do
        assert_equal "1,327.53", @tt.at('tr.total td.value').inner_text # formatted version of 1234.0 + 93.53
      end
    end
    
    context "when showing more_data" do
      setup do
        @dt = parsed_stats_table([@dummy_datapoint_1, @dummy_datapoint_2], @table_options.merge(:show_more_info => true))
      end
      
      should "show more_data column" do
        assert @dt.at('th.more_info')
        assert @dt.at('td.more_info')
      end
      
      should "adjust multiplier when styling description background position to make graph" do
        expected_position = 7.1*(100.0/@dummy_datapoint_1.value.to_f)*@dummy_datapoint_2.value.to_f #full length is 740px, scale so max value is 100%: (800/100)*(100.0/max_value)*datapoint.value.to_f
        actual_position = @dt.at(".selected td.description")["style"].scan(/([\d\.]+)px/).to_s
        assert_in_delta(expected_position, actual_position, 0.1)
      end

      should "link to polymorphic url for datapoint area and subject" do
        assert_dom_equal link_to(image_tag('inspect.gif', :alt => "See breakdown of this figure", :class => "icon"), [@area, @subject_1]), @dt.at('td.more_info a').to_s
      end
    end
    
  end

  context 'social_networking_link_for object' do
    setup do
      @member = Factory(:member)
      @member.facebook_account_name = 'bar'
    end
    
    should 'return single_social networking links for object if only one' do
      assert_equal "#{facebook_link_for(@member.facebook_account_name)}", social_networking_links_for(@member)
    end 
    
    should 'show link to add social_networking_info if none known' do
      @member.facebook_account_name = nil
      @parish_council = Factory(:parish_council)
      assert_equal "None known. #{link_to('Add social networking info now?', new_user_submission_path(:user_submission => {:item_id => @member.id, :item_type => 'Member', :submission_type => 'social_networking_details'}))}", social_networking_links_for(@member)
      assert_equal "None known. #{link_to('Add social networking info now?', new_user_submission_path(:user_submission => {:item_id => @parish_council.id, :item_type => 'ParishCouncil', :submission_type => 'social_networking_details'}))}", social_networking_links_for(@parish_council)
    end
    
    should 'return all social networking links for member' do
      @member.twitter_account_name = 'foo'
      assert_equal "#{twitter_link_for(@member.twitter_account_name)} #{facebook_link_for(@member.facebook_account_name)}", social_networking_links_for(@member)
    end
  end

  private
  def stale_factory_object(name, options={})
    obj = Factory(name, options)
    obj.stubs(:created_at => 8.days.ago, :updated_at => 8.days.ago)
    obj
  end
  
  def parsed_stats_table(datapoints=nil, options={})
    Hpricot(statistics_table(datapoints, options))
  end
end
