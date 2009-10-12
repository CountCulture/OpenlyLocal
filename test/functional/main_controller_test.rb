require 'test_helper'

class MainControllerTest < ActionController::TestCase
  context "on GET to :index" do
    setup do
      @council1 = Factory(:council)
      @council2 = Factory(:another_council)
      @member = Factory(:member, :council => @council1)
      @committee = Factory(:committee, :council => @council1)
      
      @meeting = Factory(:meeting, :council => @council1, :committee => @committee)
      @news_item = Factory(:feed_entry)
      @future_meeting = Factory(:meeting, :date_held => 3.days.from_now.to_date, :council => @council1, :committee => @committee)

      get :index
    end
  
    should_assign_to :councils
    should_respond_with :success
    should_render_template :index
    should_not_set_the_flash
    
    should "have basic title" do
      assert_select "title", /Openly Local.+Local Government/
    end
    
    should "list latest parsed councils" do
      assert_select "#latest_councils" do
        assert_select "li", 1 do # only #council1 has members and therefore is considered parsed
          assert_select "a", @council1.title
        end
      end
    end
    
    should "list latest forthoming meetings" do
      assert_select "#forthcoming_meetings" do
        assert_select "li", 1 do 
          assert_select "a", /#{@meeting.title}/
        end
      end
    end
    
    should "list latest latest councillors" do
      assert_select "#latest_councillors" do
        assert_select "li", 1 do 
          assert_select "a", /#{@member.title}/
        end
      end
    end
    
    should "show latest news from blog" do
      assert_select "#site_news" do
        assert_select "h4", /#{@news_item.title}/
      end
    end
  end
end
