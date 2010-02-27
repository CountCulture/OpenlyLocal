require 'test_helper'

class HyperlocalSiteTest < ActiveSupport::TestCase
  subject { @hyperlocal_site }
  
  context "The HyperlocalSite class" do
    setup do
      @hyperlocal_site = Factory(:hyperlocal_site)
    end
    
    should_validate_presence_of :title
    should_validate_presence_of :url
    should_belong_to :hyperlocal_group
    should_belong_to :council
    should_have_many :feed_entries
    should_allow_values_for :platform, "Ning"
    should_not_allow_values_for :platform, "foo"
    should_not_allow_mass_assignment_of :approved
    
    should_have_db_column :email
    should_have_db_column :description
    should_have_db_column :lat
    should_have_db_column :lng
    should_have_db_column :distance_covered
    should_have_db_column :feed_url
    should_have_db_column :platform
    should_have_db_column :area_covered
    should_have_db_column :country
    should_have_db_column :approved
    should_have_db_column :party_affiliation
    
    should "act as mappable" do
      assert HyperlocalSite.respond_to?(:find_closest)
    end
    
    should "include TwitterAccountMethods mixin" do
      assert HyperlocalSite.new.respond_to?(:twitter_account_name)
    end
    
    should "validate presence of lat on create" do
      h = Factory.build(:hyperlocal_site, :lat => nil)
      assert !h.valid?
      assert_equal "can't be blank", h.errors[:lat]
      @hyperlocal_site.update_attribute(:lat, nil)
      assert @hyperlocal_site.valid?
    end
     
    should "validate presence of lng on create" do
      h = Factory.build(:hyperlocal_site, :lng => nil)
      assert !h.valid?
      assert_equal "can't be blank", h.errors[:lng]
      @hyperlocal_site.update_attribute(:lng, nil)
      assert @hyperlocal_site.valid?
    end   
        
    should "validate presence of distance_covered on create" do
      h = Factory.build(:hyperlocal_site, :distance_covered => nil)
      assert !h.valid?
      assert_equal "can't be blank", h.errors[:distance_covered]
      @hyperlocal_site.update_attribute(:distance_covered, nil)
      assert @hyperlocal_site.valid?
    end   
        
    should "validate presence of description on create" do
      h = Factory.build(:hyperlocal_site, :description => nil)
      assert !h.valid?
      assert_equal "can't be blank", h.errors[:description]
      @hyperlocal_site.update_attribute(:description, nil)
      assert @hyperlocal_site.valid?
    end   
        
    context "should have named_scope model that should" do
      should "return only approved hyperlocal_sites" do
        approved_site = Factory(:approved_hyperlocal_site)
        assert_equal [approved_site], HyperlocalSite.approved
      end
    end
    
    should "delegate region to council" do
      council = Factory(:council, :region => "London")
      @hyperlocal_site.council = council
      assert_equal "London", @hyperlocal_site.region
    end
    
    should "return nil for region when no associated council" do
      assert_nil @hyperlocal_site.region
    end
    
    context "when returning independent sites" do
      should "return those that don't belong to group" do
        group_hyperlocal_site = Factory(:hyperlocal_site, :hyperlocal_group => Factory(:hyperlocal_group))
        assert_equal [@hyperlocal_site], HyperlocalSite.independent(true)
      end
      
      should "return those that belong to group when false passed as parameter" do
        group_hyperlocal_site = Factory(:hyperlocal_site, :hyperlocal_group => Factory(:hyperlocal_group))
        assert_equal [@hyperlocal_site, group_hyperlocal_site], HyperlocalSite.independent(false)
      end
    
    end
  end
  
  context "A HyperlocalSite instance" do
    setup do
      @hyperlocal_site = Factory(:hyperlocal_site)
    end
    
    should "include title in to_param method" do
      @hyperlocal_site.title = "some title-with/stuff"
      assert_equal "#{@hyperlocal_site.id}-some-title-with-stuff", @hyperlocal_site.to_param
    end
    
    context "when returning google_cse_url" do
      should "return url with slash and asterix added if no slash on the end" do
        assert_equal "http://foo.com/*", HyperlocalSite.new(:url => "http://foo.com").google_cse_url
        assert_equal "http://foo.com/bar/*", HyperlocalSite.new(:url => "http://foo.com/bar").google_cse_url
        assert_equal "http://foo.com/bar/baz/*", HyperlocalSite.new(:url => "http://foo.com/bar/baz").google_cse_url
      end
      
      should "return url with asterix added if slash already on the end" do
        assert_equal "http://foo.com/*", HyperlocalSite.new(:url => "http://foo.com/").google_cse_url
        assert_equal "http://foo.com/bar/*", HyperlocalSite.new(:url => "http://foo.com/bar/").google_cse_url
        assert_equal "http://foo.com/bar/baz/*", HyperlocalSite.new(:url => "http://foo.com/bar/baz/").google_cse_url
      end
    end
    
    context "when approved" do
      setup do
        @dummy_tweeter = Tweeter.new('foo')
      end

      should "be tweeted about" do
        Delayed::Job.expects(:enqueue).with(kind_of(Tweeter), anything)
        @hyperlocal_site.update_attribute(:approved, true)
      end

      should "run at a priority of 1" do
        Delayed::Job.expects(:enqueue).with(anything, 1)
        @hyperlocal_site.update_attribute(:approved, true)
      end

      context "and when tweeting" do
        should "message about new parsed hyperlocal_site" do
          Tweeter.expects(:new).with(regexp_matches(/#{@hyperlocal_site.title} has been added to OpenlyLocal/), anything).returns(@dummy_tweeter)
          @hyperlocal_site.update_attribute(:approved, true)
        end

        should "include openlylocal url of site" do
          Tweeter.expects(:new).with(anything, has_entry(:url, "http://openlylocal.com/hyperlocal_sites/#{@hyperlocal_site.to_param}")).returns(@dummy_tweeter)
          @hyperlocal_site.update_attribute(:approved, true)
        end

        should "use hyperlocal_site twitter_account in message if it exists" do
          @hyperlocal_site.update_attribute(:twitter_account_name, "anyhyperlocal_site")
          Tweeter.expects(:new).with(regexp_matches(/@anyhyperlocal_site has been added/), anything).returns(@dummy_tweeter)
          @hyperlocal_site.update_attribute(:approved, true)
        end

        should "not include hyperlocal_site twitter_account in message if it has none" do
          Tweeter.stubs(:new).returns(@dummy_tweeter)
          Tweeter.expects(:new).with(regexp_matches(/@/), anything).never

          @hyperlocal_site.update_attribute(:approved, true)
        end

        should "include hyperlocal_site location in message" do
          @hyperlocal_site.update_attributes(:lng => 45, :lat => 0.123)
          Tweeter.stubs(:new).returns(@dummy_tweeter)
          Tweeter.expects(:new).with(anything, has_entries(:lat => 0.123, :long => 45)).returns(@dummy_tweeter)

          @hyperlocal_site.update_attribute(:approved, true)
        end

      end
    end

    context "when creating unapproved hyperlocal_site" do
      should "Not Tweet about it" do
        Delayed::Job.expects(:enqueue).with(kind_of(Tweeter), anything).never
        hyperlocal_site = Factory(:hyperlocal_site)
      end
    end
    
  end
  
end
