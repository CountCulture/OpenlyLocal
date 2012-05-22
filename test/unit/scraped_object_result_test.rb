require File.expand_path('../../test_helper', __FILE__)

class ScrapedObjectResultTest < ActiveSupport::TestCase
  context "A ScrapedObjectResult" do

    [:base_object_klass, :id, :title, :changes, :errors, :url, :status].each do |method|
      should "respond to instance method ##{method}" do
        assert_respond_to ScrapedObjectResult.new, method, "ScrapedObjectResult does not have instance method #{method}"
      end
    end
    
    context "when initializing from base object" do
      setup do
        @mock_errors = stub_everything
        @base_obj = stub_everything( :attributes => 
                                      { "id" => 42, "url" => "http://foo.com", "foo1" => "bar1"},
                                    :title => "foo", 
                                    :changes => { :foo => "bar" },
                                    :errors => @mock_errors
                                  )
        @scr_obj = ScrapedObjectResult.new(@base_obj)
      end
      
      should "record object's class" do
        assert_equal "Mocha::Mock", @scr_obj.base_object_klass
      end

      should "use base object's attributes" do
        assert_equal 42, @scr_obj.id
        assert_equal "http://foo.com", @scr_obj.url
      end
      
      should "ignore base object's attributes for which there is no reader method" do
        assert_nil @scr_obj.instance_variable_get("@foo1")
      end
      
      should "keep use object's title" do
        assert_equal "foo", @scr_obj.title
      end
      
      should "keep object's changes" do
        assert_equal( { :foo => "bar" }, @scr_obj.changes)
      end
      
      should "keep object's errors" do
        assert_equal @mock_errors, @scr_obj.errors
      end
      
      should "equal another ScrapedObjectResult if it refers to same object with same class and id" do
        params = { :attributes => { "id" => 42 }, :title => "bar", :changes => {}, :errors => []}
        assert_equal ScrapedObjectResult.new(@base_obj), ScrapedObjectResult.new(@base_obj)
        assert_equal ScrapedObjectResult.new(@base_obj), ScrapedObjectResult.new(stub_everything(params))
        assert_not_equal ScrapedObjectResult.new(@base_obj), ScrapedObjectResult.new(stub_everything(params.merge(:attributes => { "id" => 41 })))
      end
    end
    
    context "when setting status" do

      should "return new if base object is new" do
        assert_equal "new", new_scraped_object_result(:new_record? => true, :changed? => true).status
      end
      
      should "return new if base object was new before saving" do
        assert_equal "new", new_scraped_object_result(:new_record_before_save? => true, :changed? => true).status
      end
      
      should "return changed if base object was not new but has changed" do
        assert_equal "changed", new_scraped_object_result(:changed? => true).status
      end
      
      should "return unchanged if base object was not new and has not changed" do
        assert_equal "unchanged", new_scraped_object_result.status
      end
      
      should "return errors if base object has errors" do
        assert_match /errors/, new_scraped_object_result(:errors => ["Uhh Ohh"]).status
      end
      
      should "return errors and new if new base object has errors" do
        assert_equal "new errors", new_scraped_object_result(:new_record? => true, :errors => ["Uhh Ohh"]).status
      end
      
    end
           
    context "when initalizing changes" do
      setup do
        @scr_obj = new_scraped_object_result(:changes => { :foo => "bar", :long_text => "Hello World "*100})
      end
    
      should "truncate long strings" do
        assert @scr_obj.changes[:long_text].length < 400
      end
    end
    
  end
  
  private
  def new_scraped_object_result(options={})
    ScrapedObjectResult.new(stub_everything({:attributes => {}, :errors => []}.merge(options)))
  end
end