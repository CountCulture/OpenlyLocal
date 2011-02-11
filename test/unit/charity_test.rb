require 'test_helper'

class CharityTest < ActiveSupport::TestCase

  context "The Charity class" do
    setup do
      @charity = Factory(:charity)
    end
    
    should have_many :classification_links
    should_have_many :classifications, :through => :classification_links
    should have_many :charity_annual_reports

    should have_db_column :title
    should have_db_column :activities
    should have_db_column :charity_number
    should have_db_column :website
    should have_db_column :email
    should have_db_column :telephone
    should have_db_column :date_registered
    should validate_presence_of :charity_number
    should validate_presence_of :title
    should validate_uniqueness_of :charity_number
    should have_db_column :vat_number
    should have_db_column :contact_name
    should have_db_column :accounts_date
    should have_db_column :spending
    should have_db_column :income
    should have_db_column :date_removed
    should have_db_column :normalised_title
    should have_db_column :accounts
    should have_db_column :employees
    should have_db_column :volunteers
    should have_db_column :financial_breakdown
    should have_db_column :trustees
    should have_db_column :other_names
    should have_db_column :last_checked
    should have_db_column :facebook_account_name
    should have_db_column :youtube_account_name
    should have_db_column :feed_url
    should have_db_column :governing_document
    should have_db_column :company_number
    should have_db_column :housing_association_number
    should have_db_column :subsidiary_number
    should have_db_column :fax
    should have_db_column :area_of_benefit
    should have_db_column :signed_up_for_1010
    
    should "serialize mixed data columns" do
      %w(financial_breakdown other_names trustees accounts).each do |attrib|
        @charity.update_attribute(attrib, [{:foo => 'bar'}])
        assert_equal [{:foo => 'bar'}], @charity.reload.send(attrib), "#{attrib} attribute is not serialized"
      end
    end
    
    should "mixin SpendingStatUtilities::Base module" do
      assert Charity.new.respond_to?(:spending_stat)
    end

    should "mixin SpendingStatUtilities::Payee module" do
      assert Charity.new.respond_to?(:supplying_relationships)
    end

    should 'mixin AddressMethods module' do
      assert @charity.respond_to?(:address_in_full)
    end
        
    should "include SocialNetworkingUtilities::Base mixin" do
      assert Charity.new.respond_to?(:update_social_networking_details)
    end
    
    context "when normalising title" do
      
      should "return nil if blank" do
        assert_nil Charity.normalise_title(nil)
        assert_nil Charity.normalise_title('')
      end
      
      should "normalise title" do
        TitleNormaliser.expects(:normalise_title).with('foo bar')
        Charity.normalise_title('foo bar')
      end
      
      should "remove leading 'the' " do
        TitleNormaliser.expects(:normalise_title).with('foo trust')
        Charity.normalise_title('the foo trust')
      end
      
      should "remove leading 'the' from a word" do
        TitleNormaliser.expects(:normalise_title).with('theatre trust')
        Charity.normalise_title('theatre trust')
      end
    end
    
    context "when adding new charities" do
      setup do
        @new_charity_info = [{:charity_number => '98765', :title => "NEW CHARITY"},
                            {:charity_number => '8765', :title => "ANOTHER NEW CHARITY"}]
        CharityUtilities::Client.any_instance.stubs(:get_recent_charities).returns(@new_charity_info)
      end

      should "get new charities using CharityUtilities" do
        Charity.any_instance.stubs(:update_info)
        CharityUtilities::Client.any_instance.expects(:get_recent_charities).returns(@new_charity_info)
        Charity.add_new_charities
      end
      
      should "create new charities from information returned from CharityUtilities" do
        Charity.any_instance.stubs(:update_info)
        assert_difference "Charity.count", 2 do
          Charity.add_new_charities
        end
      end
      
      should "update info for newly-created charities" do
        Charity.any_instance.expects(:update_info).twice
        Charity.add_new_charities
      end
      
      should "return charities" do
        Charity.any_instance.stubs(:update_info)
        charities = Charity.add_new_charities
        assert_equal 2, charities.size
        assert_kind_of Charity, charities.first
      end
      
      context "and problem updating info on charities" do
        setup do
          Charity.any_instance.stubs(:update_from_charity_register).returns(true)
        end

        should "still save basic charity details" do
          Charity.any_instance.expects(:update_social_networking_details_from_website).raises
          assert_difference "Charity.count", 2 do
            charities = Charity.add_new_charities
          end
        end
        
        should "not raise exception if Timeout:Error" do
          Charity.any_instance.expects(:update_social_networking_details_from_website).raises(Timeout::Error)
          
          assert_nothing_raised() { Charity.add_new_charities }
        end
      end
      
      context "and specific dates given" do
        setup do
          Charity.any_instance.stubs(:update_info)
        end

        should "get new charities between given dates" do
          Charity.any_instance.stubs(:update_info)
          start_date, end_date = 1.month.ago, 2.weeks.ago
          CharityUtilities::Client.any_instance.expects(:get_recent_charities).with(start_date, end_date).returns(@new_charity_info)
          Charity.add_new_charities(:start_date => start_date, :end_date => end_date)
        end
      end
      
      context "and charity with charity number already exists" do
        setup do
          Factory(:charity, :charity_number => '8765')
        end

        should "not create another charity with charity number" do
          Charity.any_instance.stubs(:update_info)
          assert_difference "Charity.count", 1 do
            Charity.add_new_charities
          end
        end
        
        should "update info only for new charity" do
          Charity.any_instance.expects(:update_info) #once
          Charity.add_new_charities
        end
        
        should "not raise exception" do
          Charity.any_instance.stubs(:update_info)
          assert_nothing_raised(Exception) { Charity.add_new_charities }
        end
        
        should "return all charities, even ones not saved" do
          Charity.any_instance.stubs(:update_info)
          charities = Charity.add_new_charities
          assert_equal 2, charities.size
          assert_kind_of Charity, charities.first
          unsaved_charity = charities.detect{ |c| c.new_record? }
          assert_equal '8765', unsaved_charity.charity_number
        end
      end
      
    end
    
  end

  context "an instance of the Charity class" do
    setup do
      @charity = Factory(:charity)
    end

    context "when saving" do
      should "normalise title" do
        @charity.expects(:normalise_title)
        @charity.save!
      end
  
      should "save normalised title" do
        @charity.title = "The Foo & Baz Trust. "
        @charity.save!
        assert_equal "foo and baz trust", @charity.reload.normalised_title
      end
    end
    
    should "alias website as url" do
      assert_equal 'http://foo.com', Charity.new(:website => 'http://foo.com').url
    end
    
    context "when setting website" do

      should "clean up using url_normaliser" do
        assert_equal 'http://foo.com', Charity.new(:website => 'foo.com').website
      end
    end

    context "when returning foaf version of telephone number" do

      should "return nil if telephone blank" do
        assert_nil @charity.foaf_telephone
      end

      should "return formatted number" do
        @charity.telephone = "0162 384 298"
        assert_equal "tel:+44-162-384-298", @charity.foaf_telephone
      end
    end

    context "when returning charity commission url" do
      should "build url using charity number" do
        assert_equal "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/SearchResultHandler.aspx?RegisteredCharityNumber=#{@charity.charity_number}&SubsidiaryNumber=0", @charity.charity_commission_url
      end

    end

    context "when returning resource_uri" do
      should 'return OpenCharities uri for charity' do
        assert_equal "http://opencharities.org/id/charities/#{@charity.charity_number}", @charity.resource_uri
      end
    end
    
    should "use title in to_param method" do
      @charity.title = "some title-with/stuff"
      assert_equal "#{@charity.id}-some-title-with-stuff", @charity.to_param
    end
    
    should "return nil for twitter_list_name" do
      assert_nil @charity.twitter_list_name
    end
    
    context "when assigning info to accounts" do
      setup do
        @accounts_info = [ { :accounts_date => '31 Mar 2009', :income => '1234', :spending => '2345', :accounts_url => 'http://charitycommission.gov.uk/accounts2.pdf'},
                           { :accounts_date => '31 Mar 2008', :income => '123', :spending => '234', :accounts_url => 'http://charitycommission.gov.uk/accounts1.pdf'}]
      end

      should "used given info to set accounts attribute" do
        @charity.accounts = @accounts_info
        assert_equal @accounts_info, @charity.accounts
      end
      
      should "used first year to set current accounts attributes" do
        @charity.accounts = @accounts_info
        assert_equal '31 Mar 2009'.to_date, @charity.accounts_date
        assert_equal 1234, @charity.income
        assert_equal 2345, @charity.spending
      end
      
      should "not raise excption if no accounts" do
        assert_nothing_raised(Exception) { @charity.accounts = [] }
      end
      
    end
    context "when updating info" do
      setup do
        @charity.stubs(:update_from_charity_register).returns(true)
      end

      should "update from charity register" do
        @charity.expects(:update_from_charity_register)
        @charity.update_info
      end
      
      should "update social networking info from website" do
        @charity.expects(:update_social_networking_details_from_website)
        @charity.update_info
      end
      
      context "and new record after updating from register" do
        should "not update social networking info" do
          new_charity = Charity.new
          new_charity.stubs(:update_from_charity_register)
          new_charity.expects(:update_social_networking_details_from_website).never
          
          new_charity.update_info
        end
      end
      
    end
    
    context "when updating from register" do
      should "get info using charity utilities" do
        dummy_client = stub
        CharityUtilities::Client.expects(:new).with(:charity_number => @charity.charity_number).returns(dummy_client)
        dummy_client.expects(:get_details).returns({})
        @charity.update_from_charity_register
      end
      
      should "update using info returned from charity utilities" do
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff')
        @charity.update_from_charity_register
        assert_equal 'foo stuff', @charity.reload.activities
      end
      
      should "not fail if there are unknown attributes" do
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff', :foo => 'bar')
        assert_nothing_raised(Exception) { @charity.update_from_charity_register }
        assert_equal 'foo stuff', @charity.reload.activities
      end
      
      should "not overwrite existing entries with blank ones" do
        @charity.update_attribute(:website, 'http://foo.com')
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff', :website => '')
        @charity.update_from_charity_register
        assert_equal 'http://foo.com', @charity.reload.website
      end
      
      should "update last_checked time" do
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff', :website => '')
        @charity.update_from_charity_register
        assert_in_delta Time.now, @charity.reload.last_checked, 2
      end
      
      should "not update last_checked time if problem saving @charity" do
        @charity.title = nil
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff')
        assert !@charity.update_from_charity_register
        assert_nil @charity.reload.last_checked
      end
      
    end
  end

end
