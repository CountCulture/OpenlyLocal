require 'test_helper'

class WardsControllerTest < ActionController::TestCase

  def setup
    @ward = Factory(:ward)
    @council = @ward.council
    @member = Factory(:member, :council => @council)
    @ex_member = Factory(:member, :council => @council, :date_left => 1.month.ago)
    @ward.members << @member
    @ward.members << @ex_member
  end

  # show test
  context "on GET to :show" do

    should "route to show action with id" do
      assert_routing "wards/23", {:controller => "wards", :action => "show", :id => "23"} #default route
    end

    should "route resource to show action" do
      assert_routing "id/wards/23", {:controller => "wards", :action => "show", :id => "23", :redirect_from_resource => true}
    end

    should "route ward identified by snac_id to show action" do
      assert_routing "wards/snac_id/23", {:controller => "wards", :action => "show", :snac_id => "23"}
      assert_routing "wards/snac_id/23.xml", {:controller => "wards", :action => "show", :snac_id => "23", :format => "xml"}
      assert_routing "wards/snac_id/23.json", {:controller => "wards", :action => "show", :snac_id => "23", :format => "json"}
      assert_routing "wards/snac_id/23.rdf", {:controller => "wards", :action => "show", :snac_id => "23", :format => "rdf"}
    end

    context "with basic request" do
      setup do
        get :show, :id => @ward.id
      end

      should_assign_to(:ward) { @ward }
      should_respond_with :success
      should_render_template :show

      should "show ward in title" do
        assert_select "title", /#{@ward.title}/
      end

      should "show link to resource uri in head" do
        assert_select "link[rel*='primarytopic'][href*='/id/wards/#{@ward.id}']"
      end

      should "show council in title" do
        assert_select "title", /#{@ward.council.title}/
      end

      should "list current members" do
        assert_select "div#members li a", @member.title
        assert_select "div#members li a", :text => @ex_member.title, :count => 0
      end

      should "not show list of committees" do
        assert_select "#committees", false
      end
      should "not show list of meetings" do
        assert_select "#meetings", false
      end

      should "not show link to police neighbourhood team" do
        assert_select "dd", :text => /neighbourhood police team/i, :count => 0
      end

      should "not show statistics" do
        assert_select "#grouped_datapoints", false
      end
    end

    context "with basic request and ward identified by snac_id" do
      setup do
        @ward.update_attribute(:snac_id, "AB12")
        get :show, :snac_id => @ward.snac_id
      end

      should_assign_to(:ward) { @ward }
      should_respond_with :success
      should_render_template :show

      should "show ward in title" do
        assert_select "title", /#{@ward.title}/
      end
    end

    context "with basic request when ward has additional attributes" do
      setup do
        @ward.update_attributes(:police_team => Factory(:police_team))
        @ward.committees << @committee = Factory(:committee, :council => @council)
        @meeting = Factory(:meeting, :committee => @committee, :council => @council)
        @datapoint = Factory(:datapoint, :area => @ward)
        @another_datapoint = Factory(:datapoint, :area => @ward)
        @graphed_datapoint = Factory(:datapoint, :area => @ward)
        @graphed_datapoint_topic = @graphed_datapoint.dataset_topic       
        dummy_grouped_datapoints = { stub_everything(:title => "demographics") => [@datapoint], 
                                     stub_everything(:title => "misc", :display_as => "in_words") => [@another_datapoint], 
                                     stub_everything(:title => "religion", :display_as => "graph") => [@graphed_datapoint]
                                    }
        @poll = Factory(:poll, :area => @ward)
        Ward.any_instance.stubs(:grouped_datapoints).returns(dummy_grouped_datapoints)
        get :show, :id => @ward.id
      end

      should_respond_with :success

      should "show link to committee" do
        assert_select "#committees a", /#{@committee.title}/
      end

      should "show ward committee meetings" do
        assert_select "#meetings li", /#{@meeting.title}/
      end

      should "show link to police neighbourhood team" do
        assert_select "dt", /neighbourhood police team/i
      end

      should "show link to polls" do
        assert_select "#polls a.poll_link"
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
          assert_select "#grouped_datapoints .datapoint a[href=?]", "/wards/#{@ward.to_param}/dataset_topics/#{@datapoint.dataset_topic.id}"
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

    context "with xml request" do
      setup do
        @ward.update_attributes(:police_neighbourhood_url => "http://met.gov.uk/foo")
        @ward.committees << @committee = Factory(:committee, :council => @council)
        @meeting = Factory(:meeting, :committee => @committee, :council => @council)
        get :show, :id => @ward.id, :format => "xml"
      end

      should_assign_to :ward
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'

      should "include members in response" do
        assert_select "ward member"
      end

      should "include committees in response" do
        assert_select "ward>committees>committee"
      end

      should "include meetings in response" do
        assert_select "ward meetings meeting"
      end

      should "include police_neighbourhood_url in response" do
        assert_select "ward police-neighbourhood-url"
      end
    end

    context "with rdf request" do
      setup do
        @ward.update_attributes(:snac_id => "01ABC", :os_id => "700123", :url => "http://anytown.gov.uk/ward/53")
        @ward.committees << @committee = Factory(:committee, :council => @council)
        @meeting = Factory(:meeting, :committee => @committee, :council => @council)
        get :show, :id => @ward.id, :format => "rdf"
      end

      should_assign_to :ward
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/rdf+xml'

      should "show rdf headers" do
        assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
        assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
      end

      should "show alternative representations" do
        assert_match /dct:hasFormat rdf:resource.+\/wards\/#{@ward.id}.rdf/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/wards\/#{@ward.id}\"/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/wards\/#{@ward.id}.json/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/wards\/#{@ward.id}.xml/m, @response.body
      end

      should "show ward as primary resource" do
        assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/wards\/#{@ward.id}/m, @response.body
      end

      should "show rdf info for ward" do
        assert_match /rdf:Description.+rdf:about.+\/id\/wards\/#{@ward.id}/, @response.body
        assert_match /rdf:Description.+rdfs:label>#{@ward.title}/m, @response.body
        assert_match /rdf:Description.+foaf:page>#{Regexp.escape(@ward.url)}/m, @response.body
      end

      should "show ward is same as other resources" do
        assert_match /owl:sameAs.+rdf:resource.+statistics.data.gov.uk.+local-authority-ward\/#{@ward.snac_id}/, @response.body
        assert_match /owl:sameAs.+rdf:resource.+data.ordnancesurvey.co.uk\/id\/#{@ward.os_id}/, @response.body
      end

      should "show council relationship" do
        assert_match /rdf:Description.+\/id\/councils\/#{@council.id}.+openlylocal:Ward.+\/id\/wards\/#{@ward.id}/m, @response.body
      end

      should_eventually "include members in response" do
        assert_select "ward member"
      end

      should_eventually "include committees in response" do
        assert_select "ward>committees>committee"
      end

      should_eventually "include meetings in response" do
        assert_select "ward meetings meeting"
      end

    end

    context "with rdf request when no snac_id etc" do
      setup do
        get :show, :id => @ward.id, :format => "rdf"
      end

      should_assign_to :ward
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/rdf+xml'

      should "show rdf headers" do
        assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
        assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
      end

      should "show rdf info for ward" do
        assert_match /rdf:Description.+rdf:about.+\/wards\/#{@ward.id}/, @response.body
        assert_match /rdf:Description.+rdfs:label>#{@ward.title}/m, @response.body
      end

      should "not show ward is same as other resources" do
        assert_no_match /owl:sameAs.+rdf:resource.+statistics.data.gov.uk.+local-authority-ward/, @response.body
        assert_no_match /owl:sameAs.+rdf:resource.+data.ordnancesurvey.co.uk/, @response.body
      end

      should "not show missing attributes" do
        assert_no_match /rdf:Description.+foaf:page/m, @response.body
      end
    end

     context "with json request" do
       setup do
         @ward.committees << @committee = Factory(:committee, :council => @council)
         @meeting = Factory(:meeting, :committee => @committee, :council => @council)
         get :show, :id => @ward.id, :format => "json"
       end

       should_assign_to :ward
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'application/json'

       should "include members in response" do
         assert_match /ward\":.+members\":/, @response.body
       end

       should "include committees in response" do
         assert_match /ward\":.+committees\":.+#{@committee.title}/, @response.body
       end

       should "include meetings in response" do
         assert_match /ward\":.+meetings\":.+#{@meeting.url}/, @response.body
       end

     end

   end

   # edit tests
   context "on get to :edit a ward without auth" do
     setup do
       get :edit, :id => @ward.id
     end

     should_respond_with 401
   end

   context "on get to :edit a topic" do
     setup do
       stub_authentication
       get :edit, :id => @ward.id
     end

     should_assign_to :ward
     should_respond_with :success
     should_render_template :edit
     should_not_set_the_flash
     should "display a form" do
      assert_select "form#edit_ward_#{@ward.id}"
     end


     should "show button to delete ward" do
       assert_select "form.button-to[action='/wards/#{@ward.to_param}']"
     end
   end

   # update tests
   context "on PUT to :update without auth" do
     setup do
       put :update, { :id => @ward.id,
                      :ward => { :uid => 44,
                                 :name => "New name"}}
     end

     should_respond_with 401
   end

   context "on PUT to :update" do
     setup do
       stub_authentication
       put :update, { :id => @ward.id,
                      :ward => { :uid => 44,
                                 :name => "New name"}}
     end

     should_assign_to :ward
     should_redirect_to( "the show page for ward") { ward_path(@ward.reload) }
     should_set_the_flash_to "Successfully updated ward"

     should "update ward" do
       assert_equal "New name", @ward.reload.name
     end
   end

   # delete tests
   context "on delete to :destroy a ward without auth" do
     setup do
       delete :destroy, :id => @ward.id
     end

     should_respond_with 401
   end

   context "on delete to :destroy a ward" do

     setup do
       stub_authentication
       delete :destroy, :id => @ward.id
     end

     should "destroy ward" do
       assert_nil Ward.find_by_id(@ward.id)
     end
     should_redirect_to ( "the council page") { council_url(@council) }
     should_set_the_flash_to "Successfully destroyed ward"
   end
end
