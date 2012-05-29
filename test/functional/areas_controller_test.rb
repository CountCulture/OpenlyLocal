require File.expand_path('../../test_helper', __FILE__)

class AreasControllerTest < ActionController::TestCase
  
  # routing tests
  should "route ward identified by postcode to show action" do
    assert_routing "areas/postcodes/ab123n", {:controller => "areas", :action => "search", :postcode => "ab123n"}
    assert_routing "areas/postcodes/ab123n.xml", {:controller => "areas", :action => "search", :postcode => "ab123n", :format => "xml"}
    assert_routing "areas/postcodes/ab123n.json", {:controller => "areas", :action => "search", :postcode => "ab123n", :format => "json"}
    assert_routing "areas/postcodes/ab123n.rdf", {:controller => "areas", :action => "search", :postcode => "ab123n", :format => "rdf"}
    assert_recognizes( {:controller => 'areas', :action => "search"}, 'areas/search')
  end


  # show test
  context "on GET to :show" do
    setup do
     @county = Factory(:council, :name => "Big County")
     @council_1 = Factory(:council, :parent_authority => @county)
     @council_2 = Factory(:council, :name => "2nd council", :parent_authority => @county)
     @council_3 = Factory(:council, :name => "3rd council") # no parent auth
     @council_ward = Factory(:ward, :council => @council_1)
     @county_ward_1 = Factory(:ward, :council => @county, :name => "County Ward 1")
     @county_ward_2 = Factory(:ward, :council => @county, :name => "County Ward 2")
     @member_1 = Factory(:member, :ward => @council_ward, :council => @council_1)
     @county_member = Factory(:member, :ward => @county_ward, :council => @county)
     @another_county_member = Factory(:member, :ward => @county_ward, :council => @county)
     @ex_member = Factory(:member, :ward => @council_ward, :council => @council_1, :date_left => 1.month.ago)
     
     @postcode = Factory(:postcode, :code => "ZA133SL", :ward => @council_ward, :council => @council_1, :county => @county, :lat => 54.12, :lng => 1.23 )
     @another_postcode = Factory(:postcode)
    end
  
    context "with given postcode" do
      setup do
        get :search, :postcode => 'za13 3sl'
      end
  
      should assign_to(:postcode) { @postcode }
      should assign_to(:council) { @council_1 }
      should assign_to(:county) { @county }
      should assign_to(:ward) { @ward }
      should assign_to(:members) { [@member_1] }

      should respond_with :success
      should render_template :search
      should respond_with_content_type 'text/html'
      
      should 'show nice postcode in title' do
        assert_select 'title', /ZA13 3SL/
      end
      
      should 'show council' do
        assert_select 'a.council_link', /#{@council_1.title}/
      end
      
      should "list current members" do
        assert_select "a.member_link", @member_1.title
        assert_select "a.member_link", :text => @ex_member.title, :count => 0
      end

      should 'not show crime area by default' do
        assert_select '#crime_area', false
      end
      
    end
    
    context "and ward has additional attributes" do
      setup do
        @council_ward.committees << @committee = Factory(:committee, :council => @council_ward.council)
        @meeting = Factory(:meeting, :committee => @committee, :council => @council_ward.council)
        @datapoint = Factory(:datapoint, :area => @council_ward)
        @another_datapoint = Factory(:datapoint, :area => @council_ward)
        @graphed_datapoint = Factory(:datapoint, :area => @council_ward)
        @graphed_datapoint_topic = @graphed_datapoint.dataset_topic       
        dummy_grouped_datapoints = { stub_everything(:title => "demographics") => [@datapoint], 
                                     stub_everything(:title => "misc", :display_as => "in_words") => [@another_datapoint], 
                                     stub_everything(:title => "religion", :display_as => "graph") => [@graphed_datapoint]
                                    }
        @poll = Factory(:poll, :area => @council_ward)
        @police_team = Factory(:police_team)
        @council_ward.update_attributes(:police_team => @police_team)
        @police_officer = Factory(:police_officer, :police_team => @police_team)
        @inactive_police_officer = Factory(:inactive_police_officer, :police_team => @police_team)
        Ward.any_instance.stubs(:grouped_datapoints).returns(dummy_grouped_datapoints)
        @hyperlocal_site = Factory(:approved_hyperlocal_site, :lat => @postcode.lat+0.01, :lng => @postcode.lng-0.01)
      end
      
      context 'in general' do
        setup do
          get :search, :postcode => 'za13 3sl'
        end
        
        should respond_with :success

        should "show link to committee" do
          assert_select "#committees a", /#{@committee.title}/
        end

        should "show ward committee meetings" do
          assert_select "#meetings li", /#{@meeting.title}/
        end

        should "show link to police neighbourhood officers" do
          assert_select "#police_team" do
            assert_select 'li', /#{@police_officer.name}/
          end
        end

        should "not show link to inactive police neighbourhood officers" do
          assert_select "#police_team" do
            assert_select 'li', :text => /#{@inactive_police_officer.name}/, :count => 0
          end
        end

        should "show link to polls" do
          assert_select "#polls a.poll_link"
        end

        should "show link to hyperlocal_sites" do
          assert_select "#hyperlocal_sites a", @hyperlocal_site.title
        end

        should "show statistics" do
          assert_select "#grouped_datapoints"
        end

        context "when showing statistics" do
          should "show datapoints grouped by topic group" do
            assert_select "#grouped_datapoints" do
              assert_select ".demographics a", @datapoint.title
              assert_select ".stats_in_words a", @another_datapoint.title
            end
          end

          should "show link to more info on data" do
            assert_select "#grouped_datapoints .datapoint a[href=?]", "/wards/#{@council_ward.to_param}/dataset_topics/#{@datapoint.dataset_topic.id}"
          end

          should "not show datapoint groups with no data" do
            assert_select "#grouped_datapoints .foo", false
          end

          should "show graphs for those groups that should be graphed" do
            assert_select "#grouped_datapoints .graphed_datapoints #religion_graph"
          end

          should "show data in table with graphed_table class for groups that should be graphed" do
            assert_select "#grouped_datapoints .religion.graphed_datapoints"
          end
        end

      end

      context "and postcode has associated crime area" do
        setup do
          @crime_area = Factory(:crime_area, :crime_level_cf_national => 'below_average')
          comparison_data = [{"date"=>"2008-12", "value"=>"42.2"}, {"date"=>"2009-01", "value"=>"51", 'force_value' => '2.5'}, {"date"=>"2009-02", "value"=>"3.14"}]
          CrimeArea.any_instance.stubs(:crime_rate_comparison).returns(comparison_data)
          @postcode.update_attribute(:crime_area, @crime_area)
          get :search, :postcode => 'za13 3sl'
        end

        should assign_to(:postcode) { @postcode }

        should respond_with :success
        should render_template :search
        should respond_with_content_type 'text/html'


        should 'show crime area' do
          assert_select '#crime_area'
        end

        should 'show crime stats in area' do
          assert_select '#crime_area .crime_level', /below average/i
          assert_select '#crime_area #crime_rates'
        end
        
        should 'show comparison with force levels' do
          assert_select '#crime_rates .force_value', '2.5'
        end

        should 'format values to one decimal place' do
          assert_select '#crime_rates .value', '51.0'
          assert_select '#crime_rates .value', '3.1'
        end

      end

      context "with xml request" do
        setup do
          @council_ward.update_attributes(:police_neighbourhood_url => "http://met.gov.uk/foo")
          @council_ward.committees << @committee = Factory(:committee, :council => @council_1)
          @meeting = Factory(:meeting, :committee => @committee, :council => @council_1)
          @crime_area = Factory(:crime_area, :crime_level_cf_national => 'below_average')
          comparison_data = [{"date"=>"2008-12", "value"=>"42.2"}, {"date"=>"2009-01", "value"=>"51", 'force_value' => '2.5'}, {"date"=>"2009-02", "value"=>"3.1"}]
          CrimeArea.any_instance.stubs(:crime_rate_comparison).returns(comparison_data)
          @postcode.update_attribute(:crime_area, @crime_area)
          get :search, :postcode => 'za13 3sl', :format => "xml"
        end

        should assign_to(:postcode) { @postcode }
        should assign_to(:council) { @council_1 }
        should assign_to(:county) { @county }
        should assign_to(:ward) { @ward }
        should assign_to(:members) { [@member_1] }

        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/xml'

        should "return postcode" do
          assert_select "postcode>code", @postcode.code
          assert_select "postcode>lat"
          assert_select "postcode>lng"
        end

        should "include council ward in response" do
          assert_select "postcode ward"
        end

        should "include councillors in response" do
          assert_select "postcode>ward>members>member>id", @member_1.id.to_s
        end

        should "include committees in response" do
          assert_select "postcode>ward>committees>committee"
        end

        should_eventually "include neighbourhood police team in response" do
          assert_select "postcode police-team"
        end

        should "include crime_area in response" do
          assert_select "postcode crime-area"
        end

        should_eventually "include hyperlocal_sites in response" do
          assert_select "postcode>hyperlocal_sites"
        end
      end

      context "with json request" do
        setup do
          @council_ward.update_attributes(:police_neighbourhood_url => "http://met.gov.uk/foo")
          @council_ward.committees << @committee = Factory(:committee, :council => @council_1)
          @meeting = Factory(:meeting, :committee => @committee, :council => @council_1)
          get :search, :postcode => 'za13 3sl', :format => "json"
        end

        should assign_to(:postcode) { @postcode }
        should assign_to(:council) { @council_1 }
        should assign_to(:county) { @county }
        should assign_to(:ward) { @ward }
        should assign_to(:members) { [@member_1] }

        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/json'

        should "include councillors in response" do
          assert_match /postcode\":.+members\":.+id/m, @response.body
        end

        # should "include committees in response" do
        #   assert_match /ward\":.+committees\":.+#{@committee.title}/, @response.body
        # end
        # 
        # should "include meetings in response" do
        #   assert_match /ward\":.+meetings\":.+#{@meeting.url}/, @response.body
        # end
        # should "return postcode" do
        #   assert_select "postcode>code", @postcode.code
        #   assert_select "postcode>lat"
        #   assert_select "postcode>lng"
        # end
        # 
        # should "include council ward in response" do
        #   assert_select "postcode ward"
        # end
        # 
        # should "include councillors in response" do
        #   assert_select "postcode>ward>members>member>id", @member_1.id.to_s
        # end
        # 
        # should "include committees in response" do
        #   assert_select "postcode>ward>committees>committee"
        # end
        # 
        # should_eventually "include police_neighbourhood_team in response" do
        #   assert_select "postcode police-neighbourhood-url"
        # end
        # 
        # should_eventually "include hyperlocal_sites in response" do
        #   assert_select "postcode>hyperlocal_sites"
        # end
      end
    end

    context 'and no such postcode' do
      setup do
        get :search, :postcode => 'foo1'
      end
  
      should respond_with :success
      should render_with_layout
      should 'say so' do
        assert_select '.alert', /couldn't find postcode/i
      end
    end
    
    context 'and no postcode' do
      setup do
        get :search, :postcode => nil
      end
  
      should respond_with :success
      should render_with_layout
      should 'say so' do
        assert_select '.alert', /couldn't find postcode/i
      end
    end
    
    context 'and no associated ward' do
      setup do
        @another_postcode = Factory(:postcode)
        get :search, :postcode => "#{@another_postcode.code}"
      end
  
      should respond_with :success
      should render_with_layout
      should 'say no info about this area' do
        assert_select '.alert', /No info/i
      end
    end
  end
end
