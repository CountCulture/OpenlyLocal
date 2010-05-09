require 'test_helper'

class PollsControllerTest < ActionController::TestCase
  # index test
  context 'on GET to :index' do
    setup do
      @area = Factory(:ward)
      @poll_1 = Factory(:poll, :area => @area)
      @candidacy_1 = Factory(:candidacy, :poll => @poll_1, :votes => 537)
      @poll_2 = Factory(:poll, :area => @area, :date_held => 2.weeks.ago)
      @candidacy_2 = Factory(:candidacy, :poll => @poll_2, :votes => 132)
      30.times { |i| Factory(:poll, :area => @area, :date_held => i.weeks.ago) }
    end
    
    context 'in general' do
      setup do
        get :index
      end
      should_assign_to(:polls)
      should_respond_with :success
      should_render_with_layout
      
      should 'list only first page of polls' do
        assert_select 'a.poll_link', 30
      end
      
      should 'show pagination links' do
        assert_select "div.pagination"
      end
      
      should 'show page number in title' do
        assert_select 'title', /page 1/i
      end
    end
    
    context 'with xml requested' do
      setup do
        get :index, :format => 'xml'
      end
      
      should_assign_to(:polls)
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
      
      should 'list first page of polls' do
        assert_select 'polls>poll', 30
      end
      
      should 'include area' do
        assert_select 'poll>area>id'
      end
      
      should 'show pagination links' do
        assert_select "polls>total-entries"
      end
      
    end
    
    context 'with json requested' do
      setup do
        get :index, :format => 'json'
      end
      
      should_assign_to(:polls)
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'
      
      should 'list polls' do
        assert_match %r(polls.+poll.+id), @response.body
      end
      
      should 'list area' do
        assert_match %r(polls.+area.+#{@area.title}), @response.body
      end
      
      should 'include pagination info' do
        assert_match %r(total_entries.+#{Poll.count}), @response.body
      end
      
    end
    
    # context 'with csv requested' do
    #   setup do
    #     get :index, :format => 'csv'
    #   end
    #   
    #   should_respond_with :success
    #   should_render_without_layout
    #   should_respond_with_content_type 'text/csv'
    #   
    #   should 'list attributes in header' do
    #     assert_match %r(id,area_id), @response.body
    #   end
    #   
    #   should_eventually 'list polls' do
    #     assert_match %r(#{@poll.id}.+area.+#{@area.title}), @response.body
    #   end
    #         
    # end
    
    context 'with council_id supplied' do
      setup do
        @council = @area.council
        @another_council = Factory(:another_council)
        @another_council_ward = Factory(:ward, :council => @another_council)
        @council_poll = Factory(:poll, :area => @council)
        @ward_poll = Factory(:poll, :area => @area)
        @another_council_poll = Factory(:poll, :area => @another_council)
        @another_council_ward_poll = Factory(:poll, :area => @another_council_ward)
        
      end
      
      context "in general" do
        setup do
          get :index, :council_id => @council.id
        end

        should_assign_to(:polls)
        should_assign_to(:council) { @council }
        should_respond_with :success
        should_render_with_layout

        should 'not include non-council related wards' do
          assert !assigns(:polls).include?(@another_council_poll)
          assert !assigns(:polls).include?(@another_council_ward_poll)
        end

        should 'list polls' do
          assert_select 'a.poll_link'
        end

        should 'show tailor title to council' do
          assert_select 'title', /#{@council.title}/
          assert_select 'title', :text => /local authorities/i, :count => 0
        end
      end

      context 'with xml requested' do
        setup do
          get :index, :council_id => @council.id, :format => 'xml'
        end

        should_assign_to(:polls)
        should_respond_with :success
        should_render_without_layout
        should_respond_with_content_type 'application/xml'

        should 'list first page of polls' do
          assert_select 'polls>poll', 30
        end

        should 'include area' do
          assert_select 'poll>area>id'
        end

        should 'show pagination links' do
          assert_select "polls>total-entries"
        end

      end

      context 'with json requested' do
        setup do
          get :index, :council_id => @council.id, :format => 'json'
        end

        should_assign_to(:polls)
        should_respond_with :success
        should_render_without_layout
        should_respond_with_content_type 'application/json'

        should 'list polls' do
          assert_match %r(polls.+poll.+id), @response.body
        end

        should 'list area' do
          assert_match %r(polls.+area.+#{@area.title}), @response.body
        end

        should 'include pagination info' do
          assert_match %r(total_entries.+#{Poll.associated_with_council(@council).count}), @response.body
        end

      end
    end
    
  end

  # show test  
  context "on GET to :show" do
    setup do
      @area = Factory(:ward)
      @poll = Factory(:poll, :area => @area)
    end
    
    context "in general" do
      setup do
        @candidacy_1 = Factory(:candidacy, :poll => @poll, :votes => 537)
        @candidacy_2 = Factory(:candidacy, :poll => @poll, :votes => 210)
        get :show, :id => @poll.id
      end

      should_assign_to(:poll) { @poll}
      should_assign_to(:council) { @area.council}
      should_assign_to(:total_votes) { 537 + 210 }
      should_respond_with :success
      should_render_template :show
      should_render_with_layout

      should "list associated area" do
        assert_select "a", @area.title
      end

      should "list all candidacies" do
        assert_select "#candidacies" do
          assert_select ".candidacy", 2
        end
      end

      should "show poll details in title" do
        assert_select "title", /#{@area.name}/
      end


      should "caption table as Election Results" do
        assert_select "table.statistics caption", /Election Results/
      end


      should "show share block" do
        assert_select "#share_block"
      end
      
    end
    
    context 'with xml requested' do
      setup do
        @candidacy_1 = Factory(:candidacy, :poll => @poll, :votes => 537)
        get :show, :id => @poll.id, :format => 'xml'
      end
      
      should_assign_to(:poll) { @poll}
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
      
      should 'list poll details' do
        assert_select 'poll>id'
      end
      
      should 'include area' do
        assert_select 'poll>area>id'
      end
      
      should 'include candidacies' do
        assert_select 'poll>candidacies>candidacy>id'
      end
      
    end
    
    context 'with rdf requested' do
      setup do
        @area.update_attribute(:snac_id, "00ABCD")
        @poll.update_attributes(:electorate => 1234, :ballots_issued => 234, :ballots_rejected => 12)
        @candidacy_1 = Factory(:candidacy, :poll => @poll, :votes => 53)
        get :show, :id => @poll.id, :format => 'rdf'
      end
      
      should_assign_to(:poll) { @poll}
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/rdf+xml'
     
      should "show rdf headers" do
        assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openelection/m, @response.body
        assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
      end
      
      # should "show uri of council resource" do
      #   assert_match /rdf:Description.+rdf:about.+\/id\/polls\/#{@poll.id}/, @response.body
      # end
      # 
      should "show alternative representations" do
        assert_match /dct:hasFormat rdf:resource.+\/polls\/#{@poll.id}.rdf/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/polls\/#{@poll.id}\"/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/polls\/#{@poll.id}.json/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/polls\/#{@poll.id}.xml/m, @response.body
      end
      
      # should "show ward as primary resource" do
      #   assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/wards\/#{@ward.id}/m, @response.body
      # end
      # 
      should "show rdf info for poll" do
        assert_match /rdf:about.+#{@poll.resource_uri}/, @response.body
        assert_match /rdf:type.+openelection:Poll/m, @response.body        
        assert_match /openelection:electionArea.+rdf:resource.+#{@poll.area_resource_uri}/, @response.body
        
        assert_match /cal:dtstart.+#{@poll.date_held}/, @response.body
        assert_match /openelection:electorate.+#{@poll.electorate}/m, @response.body
        assert_match /openelection:ballotsIssued.+#{@poll.ballots_issued}/m, @response.body
        assert_match /openelection:rejectedBallots.+#{@poll.ballots_rejected}/m, @response.body
      end
      
      should 'not show rejected ballot details if nil' do
        assert_no_match /openelection:ballotsMissingOfficialMark/m, @response.body
      end
      
      should "show poll is same as openelectiondata uri" do
        assert_match /owl:sameAs.+rdf:resource.+openelectiondata.org\/id\/polls\/#{@poll.area.snac_id}\/#{@poll.date_held}\/member/, @response.body
      end
      
    end
    
    context 'with rdf requested and area has no snac_id' do
      setup do
        @poll.update_attributes(:electorate => 1234, :ballots_issued => 234, :ballots_rejected => 12)
        @candidacy_1 = Factory(:candidacy, :poll => @poll, :votes => 53)
        get :show, :id => @poll.id, :format => 'rdf'
      end
      
      should_assign_to(:poll) { @poll}
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/rdf+xml'
     
      should "show poll is same as openelectiondata uri using ol_identifier" do
        assert_match /owl:sameAs.+rdf:resource.+openelectiondata.org\/id\/polls\/OL_#{@poll.area.id}\/#{@poll.date_held}\/member/, @response.body
      end
      
    end
    
    context 'with json requested' do
      setup do
        @candidacy_1 = Factory(:candidacy, :poll => @poll, :votes => 537)
        get :show, :id => @poll.id, :format => 'json'
      end
      
      should_assign_to(:poll)
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'
      
      should 'list poll details' do
        assert_match %r(poll.+id), @response.body
      end
      
      should 'list area' do
        assert_match %r(poll.+area.+#{@area.title}), @response.body
      end
      
      should 'list candidacies' do
        assert_match %r(poll.+candidacies.+#{@candidacy_1.id}), @response.body
      end
      
    end
    
    context "with candidacies with no votes" do
      setup do
        @candidacy_1 = Factory(:candidacy, :poll => @poll)
        @candidacy_2 = Factory(:candidacy, :poll => @poll)
        get :show, :id => @poll.id
      end
      
      should "caption table as Election Candidates" do
        assert_select "table.statistics caption", /Election Candidates/
      end

    end
    
    context "with candidacy with associated member" do
      setup do
        @member = Factory(:member, :council => @area.council)
        @candidacy_1 = Factory(:candidacy, :poll => @poll, :member => @member)
        @candidacy_2 = Factory(:candidacy, :poll => @poll)
        get :show, :id => @poll.id
      end
      
      should "show link to member" do
        assert_select "table.statistics td a", /#{@candidacy_1.full_name}/
      end

    end
    
    context "with uncontested poll" do
      setup do
        @poll.update_attribute(:uncontested, true)
        @candidacy_1 = Factory(:candidacy, :poll => @poll)
        get :show, :id => @poll.id
      end
      
      should "say so" do
        assert_select "table.statistics caption", /uncontested/i
      end

    end
    
    context "when poll has related articles" do
      should "show them" do
        related_article = Factory(:related_article, :subject => @poll)
        get :show, :id => @poll.id
        assert_select "#related_articles a", /#{related_article.title}/i
      end
    end
  end
   
end
