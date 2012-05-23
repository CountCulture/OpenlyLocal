require File.expand_path('../../test_helper', __FILE__)

class ParishCouncilTest < ActiveSupport::TestCase

  context "the ParishCouncil class" do
    should validate_presence_of :title
    should validate_presence_of :os_id

    [ :title, :website, :os_id, :council_id, :gss_code, :council_type,
      :wdtk_name, :vat_number, :youtube_account_name, :facebook_account_name,
      :feed_url, :normalised_title,
    ].each do |column|
      should have_db_column column
    end
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

    should "include SocialNetworkingUtilities::Base mixin" do
      assert ParishCouncil.new.respond_to?(:update_social_networking_details)
    end
    
    context "when normalising title" do
      setup do
        @original_title_and_normalised_title = {
          "Foo Bar Parish Council" => "foo bar",
          "Foo & Bar Council" => "foo and bar",
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
    
    context "when reconciling parish councils" do
      setup do
        @parish_1 = Factory(:parish_council, :title => "Foo Bar Parish Council")
        @parish_2 = Factory(:parish_council, :title => "Foo Baz Town Council")
        @parish_3 = Factory(:parish_council, :title => "Bar & Baz")
      end

      should "find parish whose normalised name matches normalised term" do
        # overall naive test of functionality
        assert_equal [@parish_2], ParishCouncil.reconcile(:q => 'Foo Baz Council')
        assert_equal [@parish_1], ParishCouncil.reconcile(:q => 'Foo Bar')
        assert_equal [@parish_3], ParishCouncil.reconcile(:q => 'Bar and Baz Council')
      end
      
      should "normalise term" do
        ParishCouncil.expects(:normalise_title).with('Foo Baz Council')
        ParishCouncil.reconcile(:q => 'Foo Baz Council')
      end
      
      should "return nil if term is blank" do
        assert_nil ParishCouncil.reconcile
        assert_nil ParishCouncil.reconcile(:q => nil)
        assert_nil ParishCouncil.reconcile(:q => '')
      end
      
      should "find Parish Councils matching normalised term" do
        ParishCouncil.stubs(:normalise_title).returns('foobaz')
        ParishCouncil.expects(:find_all_by_normalised_title).with('foobaz')
        ParishCouncil.reconcile(:q => 'Foo Baz Council')
      end
      
      # should 'flunk' do
      #   flunk
      # end
      
      context "and parent council passed in" do
        setup do
          @county_council = Factory(:generic_council)
          @council = Factory(:council, :parent_authority => @county_council)
          @parish_1 = Factory(:parish_council, :title => "Foo Bar Parish Council")
          @parish_2 = Factory(:parish_council, :title => "Foo Baz Town Council")
          @parish_3 = Factory(:parish_council, :title => "Foo Baz Town Council", :council => @council)
        end

        should "restrict to parish with given parent council" do
          assert_equal [@parish_3], ParishCouncil.reconcile(:q => 'Foo Baz Council', :parent_council => @council)
        end

        should "include parish when given parent council is ultimate county council" do
          assert_equal [@parish_3], ParishCouncil.reconcile(:q => 'Foo Baz Council', :parent_council => @county_council)
        end
        
        # should 
      end
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
    
    should "include title in to_param method" do
      @parish_council.title = "some title-with/stuff"
      assert_equal "#{@parish_council.id}-some-title-with-stuff", @parish_council.to_param
    end

    should 'return resource_uri' do
      assert_equal "http://#{DefaultDomain}/id/parish_councils/#{@parish_council.id}", @parish_council.resource_uri
    end
    
    context "when returning openlylocal_url" do
      should "build from parish_council.to_param and default domain" do
        assert_equal "http://#{DefaultDomain}/parish_councils/#{@parish_council.to_param}", @parish_council.openlylocal_url
      end
    end
    
  end      
end
