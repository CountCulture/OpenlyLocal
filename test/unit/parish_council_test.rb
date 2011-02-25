require 'test_helper'

class ParishCouncilTest < ActiveSupport::TestCase

  context "the ParishCouncil class" do
    should validate_presence_of :title
    should validate_presence_of :os_id

    should have_db_column :title
    should have_db_column :website
    should have_db_column :os_id
    should have_db_column :council_id
    should have_db_column :gss_code
    should have_db_column :wdtk_name
    should have_db_column :vat_number
    should have_db_column :normalised_title
    should belong_to :council


    should 'mixin TitleNormaliser::Base module' do
      assert ParishCouncil.respond_to?(:normalise_title)
    end

    should "mixin SpendingStatUtilities::Base module" do
      assert ParishCouncil.new.respond_to?(:spending_stat)
    end

    should "mixin SpendingStatUtilities::Payee module" do
      assert ParishCouncil.new.respond_to?(:supplying_relationships)
    end

    context "when normalising title" do
      setup do
        @original_title_and_normalised_title = {
          "Foo Bar Parish Council" => "foo bar",
          "Foo Bar Council" => "foo bar",
          "Foo Bar Town Council" => "foo bar",
          " Foo\nBar \t Parish Council   " => "foo bar"
        }
      end

      should "should overload title_normaliser with custom normalising" do
        @original_title_and_normalised_title.each do |orig_title, normalised_title|
          assert_equal( normalised_title, ParishCouncil.normalise_title(orig_title), "failed for #{orig_title}")
        end
      end
    end
    
    should "alias website as url" do
      assert_equal 'http://foo.com', ParishCouncil.new(:website => 'http://foo.com').url
      assert_equal 'http://foo.com', ParishCouncil.new(:url => 'http://foo.com').website
    end
    
    
  end
  
  context "an instance of the ParishCouncil class" do
    setup do
      @parish_council = Factory(:parish_council)
    end
    
    context "when returning extended_title" do

      should "return title by default" do
        assert_equal @parish_council.title, @parish_council.extended_title
      end
      
      should "return with parent council in brackets when it has one" do
        @parish_council.council = Factory(:generic_council)
        assert_equal "#{@parish_council.title} (#{@parish_council.council.title})", @parish_council.extended_title
      end
    end
  end      
end
