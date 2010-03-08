require 'test_helper'

class PollsControllerTest < ActionController::TestCase
  
  context "on GET to :show" do
    setup do
      @area = Factory(:ward)
      @poll = Factory(:poll, :area => @area)
      @candidate_1 = Factory(:candidate, :poll => @poll, :votes => 537)
      @candidate_2 = Factory(:candidate, :poll => @poll, :votes => 210)
      get :show, :id => @poll.id
    end
  
    should_assign_to(:poll) { @poll}
    should_respond_with :success
    should_render_template :show
    should_render_with_layout
  
    should "list associated area" do
      assert_select "a", @area.title
    end
    
    should "list all candidates" do
      assert_select "#candidates" do
        assert_select ".candidate", 2
      end
    end
    
    should "show poll details in title" do
      assert_select "title", /#{@area.name}/
    end

    
    should "show share block" do
      assert_select "#share_block"
    end
    
    # should "show api block" do
    #   assert_select "#api_info"
    # end
  end  
end
