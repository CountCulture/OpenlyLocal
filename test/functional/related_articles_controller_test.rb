require File.expand_path('../../test_helper', __FILE__)

class RelatedArticlesControllerTest < ActionController::TestCase
  
  context 'on GET to :new' do
    setup do
      get :new
    end

    should respond_with :success
    should render_template :new
    should render_with_layout
    
    should assign_to :related_article
    
    should "show title" do
      assert_select 'title', /submit related article/i
    end

    should "show form" do
      assert_select "form#new_related_article"
    end

  end
  
  context 'on POST to :create' do
    setup do
      @relatable_object = Factory(:member)
      @hyperlocal_site = Factory(:approved_hyperlocal_site)
      @dummy_pingback = Pingback.new('http://foo.com', "http://openlylocal.com/members/#{@relatable_object.to_param}")
      @dummy_pingback.stubs(:title).returns('Some blog post') #easier than assigning pingback title isntance variable
      Pingback.stubs(:new).returns(@dummy_pingback)
      Pingback.any_instance.stubs(:receive_ping).returns("Thank you for linking to us") # some text response
      HyperlocalSite.stubs(:find_from_article_url).returns(@hyperlocal_site)
    end
    
    context 'in general' do
      setup do
        post :create, :related_article => { :url => 'http://foo.com', :openlylocal_url => 'http://bar.com' }
      end
      
      should_change_record_count_of :related_article, 1, 'create'

      should redirect_to('the new page') { new_related_article_url }
    
      should set_the_flash.to(/added link to related article/i)
    
      before_should 'instantiate pingback using source_uri and target_uri' do
        Pingback.expects(:new).with('http://foo.com', 'http://bar.com').returns(@dummy_pingback)
      end
    
      before_should 'process pingback using source_uri and target_uri' do
        Pingback.any_instance.expects(:receive_ping).returns("Thank you for linking to us") # some text response
      end
    
      should 'create related_article for relatable_object' do
        related_article = RelatedArticle.first(:order => 'id')
        assert_equal @relatable_object, related_article.subject
        assert_equal 'http://foo.com', related_article.url
        assert_equal @hyperlocal_site, related_article.hyperlocal_site
      end
      
    end
    
    context 'when pingback return error' do
      setup do
        Pingback.any_instance.expects(:receive_ping).returns(17) # some text response
        post :create, :related_article => { :url => 'http://foo.com', :openlylocal_url => 'http://bar.com' }
      end
      
      should_not_change("related article count") {RelatedArticle.count}

      should redirect_to('the new page') { new_related_article_url }
    
      should set_the_flash.to(/could not add/i)
          
    end
    
    context 'when no approved hyperlocal site' do
      setup do
        HyperlocalSite.expects(:find_from_article_url) # => nil
        post :create, :related_article => { :url => 'http://foo.com', :openlylocal_url => 'http://bar.com' }
      end
      
      should_not_change("related article count") {RelatedArticle.count}

      should redirect_to('the new page') { new_related_article_url }
    
      should set_the_flash.to(/could not add/i)
          
    end
  end
end
