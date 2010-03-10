require 'test_helper'

class PollsControllerTest < ActionController::TestCase
  
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
    
    context "on GET to show with candidacies with no votes" do
      setup do
        @candidacy_1 = Factory(:candidacy, :poll => @poll)
        @candidacy_2 = Factory(:candidacy, :poll => @poll)
        get :show, :id => @poll.id
      end
      
      should "caption ttable as Election Results" do
        assert_select "table.statistics caption", /Election Candidates/
      end

    end
    
    context "on GET to show with candidacy with associated member" do
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
    
  end
   
end
