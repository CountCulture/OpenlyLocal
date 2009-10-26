require 'test_helper'

class CouncilsControllerTest < ActionController::TestCase

  def setup
    @council = Factory(:council, :authority_type => "London Borough", :snac_id => "snac_1")
    @member = Factory(:member, :council => @council)
    @old_member = Factory(:member, :council => @council)
    @another_council = Factory(:another_council)
    @committee = Factory(:committee, :council => @council)
    @past_meeting = Factory(:meeting, :committee => @committee, :council => @council)
    @committee_without_meetings = Factory(:committee, :council => @council)
    @meeting = Factory(:meeting, :committee => @committee, :council => @council, :date_held => 2.days.from_now)
    @ward = Factory(:ward, :council => @council)
    @document = Factory(:document, :document_owner => @meeting)
    @past_document = Factory(:document, :document_owner => @past_meeting)
  end
  
  # index test
  context "on GET to :index" do
    
    should "route all_councils to index with include_unparsed true" do
      assert_routing("councils/all", {:controller => "councils", :action => "index", :include_unparsed => true})
      assert_routing("councils/all.xml", {:controller => "councils", :action => "index", :include_unparsed => true , :format => "xml" })
      assert_routing("councils/all.json", {:controller => "councils", :action => "index", :include_unparsed => true , :format => "json" })
    end
    
    context "with basic request" do
      setup do
        get :index
      end
  
      should_assign_to(:councils) { [@council]} # only parsed councils
      should_respond_with :success
      should_render_template :index
      should "have appropriate title" do
        assert_select "title", /UK Local Authorities\/Councils With Opened Up Data/
      end
    end
    
    context "including unparsed councils" do
      setup do
        get :index, :include_unparsed => true
      end
  
      should_assign_to(:councils) { Council.find(:all, :order => "name")} # all councils
      should_respond_with :success
      should_render_template :index
      should "class unparsed councils as unparsed" do
        assert_select "#councils .unparsed", @another_council.name
      end
      should "class parsed councils as parsed" do
        assert_select "#councils .parsed", @council.name
      end
      should "have appropriate title" do
        assert_select "title", /All UK Local Authorities\/Councils/
      end
    end
    
    context "with search term" do
      setup do
        @member = Factory(:member, :council => @another_council) # make another_council parsed
        get :index, :term => "Any"
      end
  
      should_assign_to(:councils) { [@council] }
      should_respond_with :success
      should_render_template :index
      should "have appropriate title" do
        assert_select "title", /UK Local Authorities\/Councils With Opened Up Data With Term \'Any\'/
      end
    end
    
    context "with search term and including unparsed" do
      setup do
        get :index, :term => "Anot", :include_unparsed => true
      end
  
      should_assign_to(:councils) { [@another_council] }
      should_respond_with :success
      should "have appropriate title" do
        assert_select "title", /UK Local Authorities\/Councils With Term \'Anot\'/
      end
    end
    
    context "with snac_id" do
      setup do
        @member = Factory(:member, :council => @another_council) # make another_council parsed
        get :index, :snac_id => "snac_1"
      end
  
      should_assign_to(:councils) { [@council] }
      should_respond_with :success
      should_render_template :index
      should "have appropriate title" do
        assert_select "title", /UK Local Authorities\/Councils With Opened Up Data With SNAC id \'snac_1\'/
      end
    end
    
    context "with xml requested" do
      context "and basic request" do
        setup do
          get :index, :format => "xml"
        end

        should_assign_to(:councils) { [@council]}
        should_respond_with :success
        should_render_without_layout
        should_respond_with_content_type 'application/xml'
      end
      
      context "and search term" do
        setup do
          @member = Factory(:member, :council => @another_council) # make another_council parsed
          get :index, :term => "Any", :format => "xml"
        end

        should_assign_to(:councils) { [@council] }
        should_respond_with :success
        should_render_without_layout
        should_respond_with_content_type 'application/xml'
      end
    end
    
    context "with json requested" do
      setup do
        get :index, :format => "json"
      end
  
      should_assign_to(:councils) { [@council]}
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'
    end
  end

  # show test
  context "on GET to :show " do
    
    context "with basic request" do
      setup do
        get :show, :id => @council.id
      end

      should_assign_to(:council) { @council}
      should_respond_with :success
      should_render_template :show
      should_assign_to(:members) { @council.members.current }
      should_assign_to(:committees) { [@committee] }

      should "list all members" do
        assert_select "#members li", @council.members.current.size
      end
      
      should "list all active committees" do
        assert_select "#committees li" do
          assert_select "a", /#{@committee.title}/
          assert_select "a", :text => /#{@committee_without_meetings.title}/, :count => 0
        end
      end
      
      should "have link to all committees for council including inactive" do
        assert_select "#committees a", /include inactive/i
      end
      
      should "list all wards" do
        assert_select "#wards li", @council.wards.size do
          assert_select "a", %r(#{@ward.name})
        end
      end
      
      should "list forthcoming meetings" do
        assert_equal [@meeting], assigns(:meetings)
        assert_select "#meetings li a", @meeting.title
      end
      
      should "show link to meeting calendar" do
        assert_select "a.calendar[href*='meetings.ics?council_id=#{@council.id}']"
      end
      
      should "list documents" do
        assert_equal [@past_document], assigns(:documents)
        assert_select "#documents li", @past_document.extended_title
      end
      
      should "show rdfa headers" do
        assert_select "html[xmlns:foaf*='xmlns.com/foaf']"
      end

      should "show rdfa stuff in head" do
        assert_select "head link[rel*='foaf']"
      end
      
      should "show rdfa local authority" do
        assert_select "#data span[about='[twfyl:LondonBoroughAuthority]']"
      end
      
      should "use council name as foaf:name" do
        assert_select "h1[property*='foaf:name']", @council.title
      end
      
      should "show foaf attributes for members" do
        assert_select "#members li a[rel*='foaf:member']"
      end
      
      should "show rdfa attributes for committees" do
        assert_select "#committees li a[rel*='twfyl:committee']"
      end
      
      should "show links to services if there are 10 or more", :before => lambda { 11.times { Factory(:service, :council => @council) } } do
        assert_select "#council_services"
      end
      
      should "not show links to services if there are fewer than 10" do
        assert_select "#council_services", false
      end
      
    end
          
    context "with xml requested" do
      setup do
        get :show, :id => @council.id, :format => "xml"
      end

      should_assign_to(:council) { @council}
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
      
      should "show associated members" do
        assert_select "council>members>member>first-name", @member.first_name
      end
      
      should "show associated committees" do
        assert_select "council>committees>committee>title", @committee.title
      end
      
      should "show recent activity" do
        assert_select "recent-activity>members>member>first-name", @member.first_name
      end
    
      should "show associated meetings" do
        assert_select "council>meetings>meeting>url", @meeting.url
      end
      
      should "show associated wards" do
        assert_select "council>wards>ward>url", @ward.url
      end
    end
    
    context "with json requested" do
      setup do
       get :show, :id => @council.id, :format => "json"
      end

      should_assign_to(:council) { @council}
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'

      should "show associated members" do
        assert_match /member.+#{@member.first_name}/, @response.body
      end

      should "show associated committees" do
        assert_match /committee.+#{@committee.title}/, @response.body
      end
      
      should "show associated wards" do
        assert_match /ward.+#{@ward.name}/, @response.body
      end
    end
    
    context "when council has datapoints" do
      setup do
        @datapoint = Factory(:datapoint, :council => @council)
        @dataset = @datapoint.dataset
        Council.any_instance.stubs(:datapoints).returns([@datapoint, @datapoint])
      end
      
      context "with summary" do
        setup do
          @datapoint.stubs(:summary => ["heading_1", "data_1"])
          get :show, :id => @council.id
        end
        
        should_assign_to :datapoints
        
        should "show datapoint data" do
          assert_select "#datapoints" do
            assert_select ".datapoint", 2 do
              assert_select "div", /data_1/
            end
          end
        end

        should "show links to full datapoint data" do
          assert_select "#datapoints" do
            assert_select "a.more_info[href*='datasets/#{@dataset.id}/data']"
          end
        end
      end
            
      context "without summary" do
        setup do
          @datapoint.stubs(:summary)
          get :show, :id => @council.id
        end
        
        should_assign_to(:datapoints) {[]}
        
        should "not show datapoint data" do
          assert_select "#datapoints", false
        end
      end

      context "with xml requested" do
        setup do
          @datapoint.stubs(:summary => ["heading_1", "data_1"])
          get :show, :id => @council.id, :format => "xml"
        end

        should "show associated datasets" do
          assert_select "council>datasets>dataset>id", @datapoint.dataset.id
        end
      end
      
      context "with json requested" do
        setup do
          @datapoint.stubs(:summary => ["heading_1", "data_1"])
          get :show, :id => @council.id, :format => "json"
        end

        should "show associated datasets" do
          assert_match /dataset.+#{@datapoint.dataset.title}/, @response.body
        end
      end
    end
    
    context "and party_breakdown is available" do
      setup do
        Council.any_instance.stubs(:party_breakdown => [[Party.new("Conservative"), 4], [Party.new("Labour"), 3]])
        get :show, :id => @council.id
      end
      
      should "show party breakdown" do
        assert_select "#party_breakdown"
      end
    end
    
    context "and party_breakdown has no data" do
      setup do
        Council.any_instance.stubs(:party_breakdown => [])
        get :show, :id => @council.id
      end

      should "not show party breakdown" do
        assert_select "#party_breakdown", false
      end
    end
    
    
  end  

  # new test
  context "on GET to :new without auth" do
    setup do
      get :new
    end

    should_respond_with 401
  end
  
  context "on GET to :new" do
    setup do
      stub_authentication
      get :new
    end

    should_assign_to(:council)
    should_respond_with :success
    should_render_template :new

    should "show form" do
      assert_select "form#new_council"
    end
    
    should "show possible portal_systems in form" do
      assert_select "select#council_portal_system_id"
    end
  end  

  # create test
   context "on POST to :create" do
     setup do
       @council_params = { :name => "Some Council", 
                           :url => "http://somecouncil.gov.uk"}
     end
     
     context "description" do
       setup do
         post :create, :council => @council_params
       end

       should_respond_with 401
     end
     
     context "with valid params" do
       setup do
         stub_authentication
         post :create, :council => @council_params
       end
     
       should_change "Council.count", :by => 1
       should_assign_to :council
       should_redirect_to( "the show page for council") { council_path(assigns(:council)) }
       should_set_the_flash_to "Successfully created council"
     
     end
     
     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :council => @council_params.except(:name)
       end
     
       should_not_change "Council.count"
       should_assign_to :council
       should_render_template :new
       should_not_set_the_flash
     end
   end  

   # edit test
   context "on GET to :edit without auth" do
     setup do
       get :edit, :id => @council
     end

     should_respond_with 401
   end

   context "on GET to :edit with existing record" do
     setup do
       stub_authentication
       get :edit, :id => @council
     end

     should_assign_to(:council)
     should_respond_with :success
     should_render_template :edit

     should "show form" do
       assert_select "form#edit_council_#{@council.id}"
     end
   end  

  # update test
  context "on PUT to :update" do
    setup do
      @council_params = { :name => "New Name for SomeCouncil", 
                          :url => "http://somecouncil.gov.uk/new"}
    end
    
    context "without auth" do
      setup do
        put :update, :id => @council.id, :council => @council_params
      end

      should_respond_with 401
    end
    
    context "with valid params" do
      setup do
        stub_authentication
        put :update, :id => @council.id, :council => @council_params
      end
    
      should_not_change "Council.count"
      should_change "@council.reload.name", :to => "New Name for SomeCouncil"
      should_change "@council.reload.url", :to => "http://somecouncil.gov.uk/new"
      should_assign_to :council
      should_redirect_to( "the show page for council") { council_path(assigns(:council)) }
      should_set_the_flash_to "Successfully updated council"
    
    end
    
    context "with invalid params" do
      setup do
        stub_authentication
        put :update, :id => @council.id, :council => {:name => ""}
      end
    
      should_not_change "Council.count"
      should_not_change "@council.reload.name"
      should_assign_to :council
      should_render_template :edit
      should_not_set_the_flash
    end

  end  

end
