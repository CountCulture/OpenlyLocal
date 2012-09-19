require File.expand_path('../../test_helper', __FILE__)

class PostcodesControllerTest < ActionController::TestCase
  should 'have routing for show' do
    assert_routing 'postcodes/ab123n.json', {:controller => 'postcodes', :action => 'show', :id => 'ab123n', :format => 'json'}
  end

  context 'on GET to :show' do
    context 'with existing postcode' do
      setup do
        @postcode = Factory(:postcode, :code => 'ZA133SL', :lat => 54.12, :lng => 1.23)
        get :show, :id => 'za13 3sl', :format => 'json'
      end

      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/json'

      should 'respond with postcode coordinates' do
        assert [%q({"postcode":{"lng":1.23,"lat":54.12}}), %q({"postcode":{"lat":54.12,"lng":1.23}})].include? @response.body
      end
    end

    context 'with non-existing postcode' do
      setup do
        get :show, :id => 'za13 3sl', :format => 'json'
      end

      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/json'

      should 'respond with postcode coordinates' do
        assert_equal '', @response.body
      end
    end
  end
end
