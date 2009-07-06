require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  context "link_for helper method" do

    should "return nil by default" do
      assert_nil link_for
    end
    
    should "return link for item with object title for link text" do
      obj = stale_factory_object(:committee) # poss better way of testing this. obj can be any ActiveRecord obj 
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), link_for(obj)
    end
    
    should "escape object's title" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" ) 
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link"), link_for(obj)
    end
    
    should "pass on options" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" ) 
      assert_dom_equal link_to(h(obj.title), obj, :foo => "bar", :class => "committee_link"), link_for(obj, :foo => "bar")
    end
    
    should "add given class to object class" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link bar"), link_for(obj, :class => "bar")
    end
    
    should "add new class if it has recently been created" do
      obj = Factory(:committee) 
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link new"), link_for(obj)
    end
    
    should "add updated class if it is not new but has recently been updated" do
      obj = Factory(:committee) 
      obj.stubs(:created_at => 8.days.ago)
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link updated"), link_for(obj)
    end
    
    should "not add new class if it has recently been created but basic is requested" do
      obj = Factory(:committee) 
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), link_for(obj, :basic => true)
    end
    
    should "not add updated class if it is not new but has recently been updated but basic is requested" do
      obj = Factory(:committee) 
      obj.stubs(:created_at => 8.days.ago)
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), link_for(obj, :basic => true)
    end
  end
  
  context "basic_link_for helper method" do

    should "return nil by default" do
      assert_nil basic_link_for
    end
    
    should "return link for item with object title for link text" do
      obj = stale_factory_object(:committee) # poss better way of testing this. obj can be any ActiveRecord obj 
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), basic_link_for(obj)
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
  
  context "council_page_for helper method" do

    should "return link based on url" do
      obj = stub(:url => "http://somecouncil/meeting")
      assert_dom_equal link_to("official page", "http://somecouncil/meeting", :class => "official_page external"), council_page_for(obj)
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
    
    should "return unordered list of objects using link_for helper method" do
      assert_dom_equal "<ul><li>#{link_for(@obj1)}</li><li>#{link_for(@obj2)}</li></ul>", list_all([@obj1,@obj2])
    end
    
    should "return unordered list of single object" do
      assert_dom_equal "<ul><li>#{link_for(@obj1)}</li></ul>", list_all(@obj1)
    end
  end
  
  private
  def stale_factory_object(name, options={})
    obj = Factory(name, options)
    obj.stubs(:created_at => 8.days.ago, :updated_at => 8.days.ago)
    obj
  end
end