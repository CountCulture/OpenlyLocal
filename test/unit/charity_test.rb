require 'test_helper'

class CharityTest < ActiveSupport::TestCase

  context "The Charity class" do
    setup do
      @charity = Factory(:charity)
    end
    
    should have_many :supplying_relationships
    should have_db_column :title
    should have_db_column :activities
    should have_db_column :charity_number
    should have_db_column :website
    should have_db_column :email
    should have_db_column :telephone
    should have_db_column :date_registered
    # should have_db_column :charity_commission_url
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
    
    should "mixin SpendingStat::Base module" do
      assert Charity.new.respond_to?(:spending_stat)
    end

    should 'mixin AddressMethods module' do
      assert @charity.respond_to?(:address_in_full)
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

    should "use title in to_param method" do
      @charity.title = "some title-with/stuff"
      assert_equal "#{@charity.id}-some-title-with-stuff", @charity.to_param
    end

  end

end
