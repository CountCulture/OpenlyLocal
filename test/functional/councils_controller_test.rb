require 'test_helper'

class CouncilsControllerTest < ActionController::TestCase

  def setup
    @council = Factory(:council, :authority_type => "London Borough", :snac_id => "snac_1", :country => "England", :region => "London")
    @member = Factory(:member, :council => @council)
    @old_member = Factory(:member, :council => @council)
    @ex_member = Factory(:member, :council => @council, :date_left => 1.month.ago)
    @another_council = Factory(:another_council)
    @committee = Factory(:committee, :council => @council)
    @past_meeting = Factory(:meeting, :committee => @committee, :council => @council)
    @committee_without_meetings = Factory(:committee, :council => @council)
    @meeting = Factory(:meeting, :committee => @committee, :council => @council, :date_held => 2.days.from_now)
    @ward = Factory(:ward, :council => @council)
    @document = Factory(:document, :document_owner => @meeting)
    Document.record_timestamps = false # update timestamp without triggering callbacks
    @past_document = Factory(:document, :document_owner => @past_meeting, :created_at => 2.days.ago)
    Document.record_timestamps = true
  end
  
  # index test
  context "on GET to :index" do
    
    should "route all_councils to index with include_unparsed true" do
      assert_routing("councils/all", {:controller => "councils", :action => "index", :include_unparsed => true})
      assert_routing("councils/all.xml", {:controller => "councils", :action => "index", :include_unparsed => true , :format => "xml" })
      assert_routing("councils/all.json", {:controller => "councils", :action => "index", :include_unparsed => true , :format => "json" })
    end
    
    should "route regular resource routes for index action" do
      assert_routing("councils", {:controller => "councils", :action => "index"})
      assert_routing("councils.xml", {:controller => "councils", :action => "index", :format => "xml" })
      assert_routing("councils.json", {:controller => "councils", :action => "index", :format => "json" })
    end
    
    should "route regular resource routes for show action" do
      assert_routing("councils/23", {:controller => "councils", :action => "show", :id => "23"})
      assert_routing("councils/23.xml", {:controller => "councils", :action => "show", :id => "23", :format => "xml" })
      assert_routing("councils/23.json", {:controller => "councils", :action => "show", :id => "23", :format => "json" })
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
      
      should "list parsed councils" do
        assert_select "#councils .council", Council.parsed({}).all.size
        assert_select "#council_#{@council.id}"
      end
      
      should "link to filter by country" do
        assert_select "#council_#{@council.id}" do
          assert_select ".area a[href*='country=England']", /England/
        end
      end
      
      should "link to filter by region" do
        assert_select "#council_#{@council.id}" do
          assert_select ".area a[href*='region=London']", /London/
        end
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
        assert_select "title", /UK Local Authorities\/Councils With Opened Up Data With \'Any\'/i
      end
    end
    
    context "with search term and including unparsed" do
      setup do
        get :index, :term => "Anot", :include_unparsed => true
      end
  
      should_assign_to(:councils) { [@another_council] }
      should_respond_with :success
      should "have appropriate title" do
        assert_select "title", /UK Local Authorities\/Councils With \'Anot\'/i
      end
    end
    
    context "with no results" do
      setup do
        get :index, :term => "foobar"
      end
  
      should_respond_with :success
      should "show message" do
        assert_select "p.alert", /No councils found/i
      end
    end
    
    context "restricted to region" do
      setup do
        @member = Factory(:member, :council => @another_council) # make another_council parsed
        @another_council.update_attribute(:region, "North-West")
        get :index, :region => "North-West"
      end
  
      should_assign_to(:councils) { [@another_council] }
      should_respond_with :success
      should_render_template :index
      should "have appropriate title" do
        assert_select "title", /UK Local Authorities\/Councils in North-West/i
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
    
    context "with rdf request and missing attributes" do
      setup do
        get :index, :format => "rdf"
      end
     
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/rdf+xml'
     
      should "show rdf headers" do
        assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
        assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
      end
      
      should "list councils" do
        assert_match /rdf:Description.+rdf:about.+\/id\/councils\/#{@council.id}/m, @response.body
        assert_match /rdf:Description.+rdfs:label.+#{@council.title}/m, @response.body
      end
            
      should "include parsed and unparsed councils" do
        assert_match /rdf:Description.+rdf:about.+\/id\/councils\/#{@council.id}/m, @response.body
        assert_match /rdf:Description.+rdf:about.+\/id\/councils\/#{@another_council.id}/m, @response.body
      end
      
    end

  end

  # show test
  context "on GET to :show " do
    should "route resource to show action" do
      assert_routing "/councils/23", {:controller => "councils", :action => "show", :id => "23"} #default route
      assert_routing "/id/councils/23", {:controller => "councils", :action => "show", :id => "23", :redirect_from_resource => true}
    end
    
    should "route council identified by snac_id to show action" do
      assert_routing "councils/snac_id/23", {:controller => "councils", :action => "show", :snac_id => "23"}
      assert_routing "councils/snac_id/23.xml", {:controller => "councils", :action => "show", :snac_id => "23", :format => "xml"}
      assert_routing "councils/snac_id/23.json", {:controller => "councils", :action => "show", :snac_id => "23", :format => "json"}
      assert_routing "councils/snac_id/23.rdf", {:controller => "councils", :action => "show", :snac_id => "23", :format => "rdf"}
    end

    should "route council identified by os_id to show action" do
      assert_routing "councils/os_id/1023", {:controller => "councils", :action => "show", :os_id => "1023"}
      assert_routing "councils/os_id/1023.xml", {:controller => "councils", :action => "show", :os_id => "1023", :format => "xml"}
      assert_routing "councils/os_id/1023.json", {:controller => "councils", :action => "show", :os_id => "1023", :format => "json"}
      assert_routing "councils/os_id/1023.rdf", {:controller => "councils", :action => "show", :os_id => "1023", :format => "rdf"}
    end

    context "when passed redirect_from_resource as parameter" do
      setup do
        get :show, :id => @council.id, :redirect_from_resource => true
      end

      should_respond_with 303
      should_redirect_to("the council show page") {council_url(:id => @council.id)}
    end
    
    context "with basic request" do
      setup do
        Council.any_instance.stubs(:party_breakdown => [])
        get :show, :id => @council.id
      end

      should_assign_to(:council) { @council}
      should_respond_with :success
      should_render_template :show
      should_assign_to(:members) { @council.members.current }
      should_assign_to(:committees) { [@committee] }
      
      should "show council name in meta description" do
        assert_select "meta[name=description][content*=?]", @council.title
      end

      should "list all active members" do
        assert_select "#members li", @council.members.current.size
        assert_select "#members a", :text => /#{@ex_member.title}/, :count => 0
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
        assert_select "a.calendar[href*='councils/#{@council.id}/meetings.ics']"
      end
      
      should "not show link to police url" do
        assert_select "extra info a", :text => /police/, :count => 0
      end
      
      should "list documents" do
        assert_equal [@document, @past_document], assigns(:documents) #most recently created first
        assert_select "#documents li", @past_document.extended_title
      end
      
      should "show link to resource uri in head" do
        assert_select "link[rel*='primarytopic'][href*='/id/councils/#{@council.id}']" # uri based on controller
      end

      should "show links to services if there are 10 or more", :before => lambda { 11.times { Factory(:service, :council => @council) } } do
        assert_select "#council_services"
      end
      
      should "not show links to services if there are fewer than 10" do
        assert_select "#council_services", false
      end
      
      should "not show child councils if there is none" do
        assert_select "#child_councils", false
      end
      
      should "not show parent council if there is none" do
        assert_select "#associated_councils", :text => /county/i, :count => 0
      end
      
      should "not show party breakdown" do
        assert_select "#party_breakdown", false
      end
      
    end
    
    context "with basic request and ward identified by snac_id" do
      setup do
        @council.update_attribute(:snac_id, "AB12")
        get :show, :snac_id => @council.snac_id
      end

      should_assign_to(:council) { @council }
      should_respond_with :success
      should_render_template :show

      should "show council in title" do
        assert_select "title", /#{@council.title}/
      end
    end

    context "with basic request and ward identified by os_id" do
      setup do
        @council.update_attribute(:os_id, "1023")
        get :show, :os_id => @council.os_id
      end

      should_assign_to(:council) { @council }
      should_respond_with :success
      should_render_template :show

      should "show council in title" do
        assert_select "title", /#{@council.title}/
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
      
      should "show recent activity" do
        assert_match /recent_activity.+members.+first_name\":\"#{@member.first_name}/, @response.body
      end
    
    end
    
    context "with rdf requested" do
      setup do
        @council.update_attributes(:wikipedia_url => "http:/en.wikipedia.org/wiki/foo", :address => "47 some street, anytown AN1 3TN", :telephone => "012 345", :url => "http://anytown.gov.uk", :os_id => "7000123", :parent_authority_id => @another_council.id, :twitter_account_name => "anytown_twitter")
        get :show, :id => @council.id, :format => "rdf"
      end
     
      should_assign_to :council
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/rdf+xml'
     
      should "show rdf headers" do
        assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
        assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
      end
      
      should "show uri of council resource" do
        assert_match /rdf:Description.+rdf:about.+\/id\/councils\/#{@council.id}/, @response.body
      end
      
      should "show council as primary resource" do
        assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/councils\/#{@council.id}/m, @response.body
      end
      
      should "show name of council" do
        assert_match /rdf:Description.+rdfs:label>#{@council.title}/m, @response.body
      end
      
      should "show type of council" do
        assert_match /rdf:type.+openlylocal:LondonBorough/m, @response.body
      end
      
      should "show alternative representations" do
        assert_match /dct:hasFormat rdf:resource.+\/councils\/#{@council.id}.rdf/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/councils\/#{@council.id}\"/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/councils\/#{@council.id}.json/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/councils\/#{@council.id}.xml/m, @response.body
      end
      
      should "show council is same as other resources" do
        assert_match /owl:sameAs.+rdf:resource.+statistics.data.gov.uk.+local-authority\/#{@council.snac_id}/, @response.body
        assert_match /owl:sameAs.+rdf:resource.+#{Regexp.escape(@council.dbpedia_resource)}/, @response.body
      end
      
      should "show council has geogrphic area of OS resource" do
        assert_match /administrative-geography:coverage.+rdf:resource.+data.ordnancesurvey.co.uk\/id\/#{@council.os_id}/, @response.body
      end
      
      should "show details of council" do
        assert_match /foaf:phone.+#{Regexp.escape(@council.foaf_telephone)}/, @response.body
        assert_match /foaf:homepage.+#{Regexp.escape(@council.url)}/, @response.body
        assert_match /vCard:Extadd.+#{Regexp.escape(@council.address)}/, @response.body
      end
      
      should "show address for member as vCard" do
        assert_match /rdf:Description.+vCard:ADR.+vCard:Extadd.+#{Regexp.escape(@council.address)}/m, @response.body
      end
      
      should "show wards" do
        assert_match /openlylocal:Ward.+rdf:resource.+\/id\/wards\/#{@ward.id}/, @response.body
        assert_match /rdf:Description.+\/id\/wards\/#{@ward.id}/, @response.body
      end
      
      should "show committees" do
        assert_match /openlylocal:LocalAuthorityCommittee.+rdf:resource.+\/id\/committees\/#{@committee.id}/, @response.body
        assert_match /rdf:Description.+\/id\/committees\/#{@committee.id}/, @response.body
      end
      
      should "show members" do
        assert_match /openlylocal:LocalAuthorityMember.+rdf:resource.+\/id\/members\/#{@member.id}/, @response.body
        assert_match /rdf:Description.+\/id\/members\/#{@member.id}/, @response.body
      end
      
      should "show relationship with parent authority" do
        assert_match /rdf:Description.+\/id\/councils\/#{@another_council.id}.+openlylocal:isParentAuthorityOf.+\/id\/councils\/#{@council.id}/m, @response.body
      end
      
      should "show twitter details" do
        get :show, :id => @council.id, :format => "rdf"
        assert_match /rdf:Description.+foaf:OnlineAccount.+twitter\.com/m, @response.body
      end
      
      should "show police force details" do
        @police_force = Factory(:police_force)
        @police_force.councils << @council
        get :show, :id => @council.id, :format => "rdf"
        assert_match /rdf:Description.+\/id\/police_forces\/#{@police_force.id}.+openlylocal:isPoliceForceFor.+\/id\/councils\/#{@council.id}/m, @response.body
      end
    end

    context "with rdf requested and child authorities" do
      setup do
        @council.child_authorities << @another_council
        get :show, :id => @council.id, :format => "rdf"
      end
     
      should_assign_to :council
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/rdf+xml'
     
      should "show relationship with child authorities" do
        assert_match /rdf:Description.+\/id\/councils\/#{@council.id}.+openlylocal:isParentAuthorityOf.+\/id\/councils\/#{@another_council.id}/m, @response.body
      end
      
      should "show child authorities" do    
        assert_match /rdf:Description.+\/id\/councils\/#{@another_council.id}/, @response.body
      end
    end

    context "with rdf request and missing attributes" do
      setup do
        @council.update_attribute(:snac_id, nil)
      end
     
      should "show rdf headers" do
        get :show, :id => @council.id, :format => "rdf"
        assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
        assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
      end
      
      should "show name of council" do
        get :show, :id => @council.id, :format => "rdf"
        assert_match /rdf:Description.+rdfs:label>#{@council.title}/m, @response.body
      end
      
      should "not show council is same as other resources" do
        get :show, :id => @council.id, :format => "rdf"
        assert_no_match /owl:sameas.+rdf:resource.+statistics.data.gov.uk/, @response.body
        assert_no_match /owl:sameas.+rdf:resource.+dbpedia/, @response.body
        assert_no_match /owl:sameAs.+rdf:resource.+data.ordnancesurvey.co.uk/, @response.body
      end
      
      should "not show missing details of council" do
        get :show, :id => @council.id, :format => "rdf"
        assert_no_match /foaf:address/, @response.body
        assert_no_match /foaf:telephone/, @response.body
      end
      
      should "not show twitter details" do
        get :show, :id => @council.id, :format => "rdf"
        assert_no_match /foaf:OnlineAccount/, @response.body
        assert_no_match /twitter\.com/, @response.body
      end
    end

    context "with basic request and council has optional attributes" do
      setup do
        @datapoint = Factory(:datapoint, :area => @council)
        @dataset_topic_grouping = Factory(:dataset_topic_grouping)
        @dataset_topic_grouping.dataset_topics << @datapoint.dataset_topic
        @hyperlocal_site = Factory(:approved_hyperlocal_site, :council => @council)

        Council.any_instance.stubs(:party_breakdown => [[Party.new("Conservative"), 4], [Party.new("Labour"), 3]])
        @council.child_authorities << @another_council # add parent/child relationship
      end
      
      should "show party breakdown" do
        get :show, :id => @council.id
        assert_select "#party_breakdown"
      end

      should "show child district authorities when they exist" do
        @council.child_authorities << @another_council
        get :show, :id => @council.id
        assert_select "dd.district_councils a", /#{@another_council.name}/
      end

      should "show parent county authority if it exists" do
        get :show, :id => @another_council.id
        assert_select "dd.county_council a", /#{@council.name}/
      end

      should "show list hyperlocal_sites" do
        get :show, :id => @council.id
        assert_select "li a", /#{@hyperlocal_site.title}/
      end

      context "with grouped_data" do
        setup do
          get :show, :id => @council.id
        end
                
        should "show data" do
          assert_select "#grouped_datapoints .datapoint", /#{@datapoint.title}/
        end
        
        should "show link to more info on data" do
          assert_select "#grouped_datapoints .datapoint a[href=?]", "/councils/#{@council.to_param}/dataset_topics/#{@datapoint.dataset_topic.id}"
        end

      end
            
      # context "with xml requested" do
      #   setup do
      #     @datapoint.stubs(:summary => ["heading_1", "data_1"])
      #     get :show, :id => @council.id, :format => "xml"
      #   end
      # 
      #   should_eventually "show associated datasets" do
      #     assert_select "council>datasets>dataset>id", @datapoint.dataset_topic.dataset_family.dataset.id.to_s
      #   end
      # end
      # 
      # context "with json requested" do
      #   setup do
      #     @datapoint.stubs(:summary => ["heading_1", "data_1"])
      #     get :show, :id => @council.id, :format => "json"
      #   end
      # 
      #   should_eventually "show associated datasets" do
      #     assert_match /dataset.+#{@datapoint.dataset_topic.dataset_family.dataset.title}/, @response.body
      #   end
      # end
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
     
       should_not_change( "Number of councils" ){"Council.count"}
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
