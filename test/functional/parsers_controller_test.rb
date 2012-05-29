require File.expand_path('../../test_helper', __FILE__)

class ParsersControllerTest < ActionController::TestCase
  
  context "when returning auth_level" do
    setup do
      @parser = Factory(:parser)
      @parser_controller = ParsersController.new
    end
    
    should "return 'parsers' by default" do
      @parser_controller.stubs(:params).returns({})
      assert_equal 'parsers', @parser_controller.send(:auth_level)
    end
    
    context "and parser instance variable set" do
      setup do
        @parser = Factory(:parser)
        @parser_controller.instance_variable_set(:@parser, @parser)
      end

      should "return underscored version of result_model for parser" do
        @parser_controller.stubs(:params).returns({})
        assert_equal @parser.result_model.underscore.pluralize, @parser_controller.send(:auth_level)
      end
      
      should "ignore result_model in params" do
        @parser_controller.stubs(:params).returns({:result_model => 'FooBar'})
        assert_equal @parser.result_model.underscore.pluralize, @parser_controller.send(:auth_level)
      end
    end
    
    context "and parser instance variable not set" do
      setup do
        @parser_controller.stubs(:params).returns({})
      end

      should "return underscored version of result_model in params" do
        @parser_controller.expects(:params).returns({:result_model => 'FooBar'})
        assert_equal 'foo_bars', @parser_controller.send(:auth_level)
      end
    end
    
  end

  # show tests
  context "on GET to :show without auth" do
    setup do
      @parser = Factory(:parser)
      @scraper = Factory(:scraper, :parser => @parser)
      get :show, :id => @parser.id
    end
  
    should respond_with 401
  end

  context "on GET to :show" do
    context "in general" do
      setup do
        @parser = Factory(:parser)
        @scraper = Factory(:scraper, :parser => @parser)
        stub_authentication
        get :show, :id => @parser.id
      end

      should assign_to :parser
      should assign_to :scrapers
      should respond_with :success
      should render_template :show

      should "show link to perform edit" do
        assert_select ".parser a", /edit/
      end

      should "list associated scrapers" do
        assert_select "#scrapers a", @scraper.title
      end

      should "show related model field" do
        assert_select ".parser strong", /related/i
      end

      should "not show share block" do
        assert_select "#share_block", false
      end
    end
    
    context "a csv_parser" do
      setup do
        @csv_parser = Factory(:csv_parser)
        @scraper = Factory(:csv_scraper, :parser => @csv_parser)
        stub_authentication
        get :show, :id => @csv_parser.id
      end

      should assign_to :parser
      should assign_to :scrapers
      should respond_with :success
      should render_template :show

      should "show link to perform edit" do
        assert_select ".csv_parser a", /edit/
      end

      should_eventually "list associated scrapers" do
        assert_select "#scrapers a", @scraper.title
      end

      should "show attribute mapping" do
        assert_select ".parser_attribute .title", /department_name/
      end
    end
  end
  
  context "on GET to :show for InfoScraper parser" do
    setup do
      @parser = Factory(:another_parser)
      @scraper = Factory(:scraper, :parser => @parser)
      stub_authentication
      get :show, :id => @parser.id
    end
  
    should assign_to :parser
    should assign_to :scrapers
    should respond_with :success
    should render_template :show
    
    should "list associated scrapers" do
      assert_select "#scrapers a", @scraper.title
    end
      
    should "not show related model field" do
      assert_select ".parser strong", :text => /related/i, :count => 0
    end
  end
  
  # new tests
  context "on GET to :new" do
    setup do
      @portal_system = Factory(:portal_system)
    end
    
    context "with no portal_system given" do
      should "raise exception" do
        stub_authentication
        assert_raise(ArgumentError) { get :new, :result_model => "Member", :scraper_type => "ItemScraper" }
      end
    end
    
    context "with no scraper_type given" do
      should "raise exception" do
        stub_authentication
        assert_raise(ArgumentError) { get :new, :portal_system_id  => @portal_system.id, :result_model => "Member" }
      end
    end
    
    context "without auth" do
      setup do
        get :new, :portal_system_id  => @portal_system.id, :result_model => "Member", :scraper_type => "ItemScraper"
      end
      should respond_with 401
    end
    
    context "for basic parser" do
      setup do
        stub_authentication
        get :new, :portal_system_id  => @portal_system.id, :result_model => "Member", :scraper_type => "ItemScraper"
      end
      
      should assign_to(:parser)
      should respond_with :success
      should render_template :new

      should "show form" do
        assert_select "form#new_parser"
      end

      should "include portal_system in hidden field" do
        assert_select "input#parser_portal_system_id[type=hidden][value=#{@portal_system.id}]"
      end
      
      should "include scraper_type in hidden field" do
        assert_select "input#parser_scraper_type[type=hidden][value='ItemScraper']"
      end
    end
    
    context "for csv parser" do
      setup do
        stub_authentication
        get :new, :portal_system_id  => @portal_system.id, :result_model => "Member", :scraper_type => "CsvScraper"
      end
      
      should respond_with :success
      should render_template :new
      
      should "assign to parser a CsvParser instance" do
        assert assigns(:parser).kind_of?(CsvParser)
      end

      should "show form" do
        assert_select "form#new_csv_parser"
      end

      should "include portal_system in hidden field" do
        assert_select "input#csv_parser_portal_system_id[type=hidden][value=#{@portal_system.id}]"
      end
      
      should "include scraper_type in hidden field" do
        assert_select "input#csv_parser_scraper_type[type=hidden][value='CsvScraper']"
      end
      
      should "not show item parser field" do
        assert_select "textarea#parser_item_parser", false
        assert_select "textarea#csv_parser_item_parser", false
      end
      
      should "show item mapping fields" do
        assert_select "#parser_attribute_parser"
      end

    end
    
  end
  
  # create test
   context "on POST to :create" do
     setup do
       @portal_system = Factory(:portal_system)
       @parser_params = Factory.attributes_for(:parser, :portal_system => @portal_system)
      end
      
      context "without auth" do
        setup do
          post :create, :parser => @parser_params
        end

        should respond_with 401
      end
      
       context "with valid params" do
         setup do
           stub_authentication
           post :create, :parser => @parser_params
         end

         should_change("Parser count", :by => 1) {Parser.count}
         should assign_to :parser
         should redirect_to( "the show page for parser") { parser_path(assigns(:parser)) }
         should set_the_flash.to "Successfully created parser"

       end
       
       context "with invalid params" do
         setup do
           stub_authentication
           post :create, :parser => @parser_params.except(:result_model)
         end

         should_not_change('The number of parsers') { Parser.count }
         should assign_to :parser
         should render_template :new
         should_not set_the_flash
       end

       context "with no scraper_type" do
         setup do
           stub_authentication
           post :create, :parser => @parser_params.except(:scraper_type)
         end

         should_not_change('The number of parsers') { Parser.count }
         should assign_to :parser
         should render_template :new
         should_not set_the_flash
       end

       context "for csv_parser" do
         setup do
           @csv_parser_params = { :result_model => "Committee",
                                  :scraper_type => 'CsvScraper',
                                  :attribute_mapping_object => [{:attrib_name => "transaction_id", :column_name => "TransactionID"},
                                                                {:attrib_name => "directorate", :column_name => "Directorate"}]}
           stub_authentication
           post :create, :csv_parser => @csv_parser_params
         end

         should_change("Parser count", :by => 1) {Parser.count}
         should assign_to :parser
         should redirect_to( "the show page for parser") { parser_path(assigns(:parser)) }
         should set_the_flash.to "Successfully created parser"
         
         should 'create new parser with given attributes' do
           assert_equal( {:transaction_id =>"transactionid", :directorate => "directorate"}, assigns(:parser).attribute_mapping)
         end

       end
       
   end  

  # edit tests
  context "on GET to :edit without auth" do
    setup do
      @portal_system = Factory(:portal_system)
      @parser = Factory(:parser, :portal_system => @portal_system)
      get :edit, :id  => @parser.id
    end
  
    should respond_with 401
  end

  context "on GET to :edit" do
    context "in general" do
      setup do
        @portal_system = Factory(:portal_system)
        @parser = Factory(:parser, :portal_system => @portal_system)
        stub_authentication
        get :edit, :id  => @parser.id
      end

      should assign_to(:parser)
      should respond_with :success
      should render_template :edit

      should "show form" do
        assert_select "form#edit_parser_#{@parser.id}" do
          assert_select "form[action='/parsers/#{@parser.id}']"
        end
      end
    end
    
    context "for csv_parser" do
      setup do
        @csv_parser = Factory(:csv_parser)
        stub_authentication
        get :edit, :id  => @csv_parser.id
      end

      should assign_to(:parser)
      should respond_with :success
      should render_template :edit

      should "show form" do
        assert_select "form#edit_csv_parser_#{@csv_parser.id}" do
          assert_select "form[action='/parsers/#{@csv_parser.id}']"
        end
      end
    end
    
  end
  
  # update test
  context "on PUT to :update" do
    setup do
      @portal_system = Factory(:portal_system)
      @parser = Factory(:parser, :portal_system => @portal_system)
      @csv_parser = Factory(:csv_parser)
      @parser_params = { :description => "New Description", 
                         :result_model => "Committee",
                         :item_parser => "foo=\"new_bar\"",
                         :attribute_parser_object => [{:attrib_name => "newfoo", :parsing_code => "barbar"}]}
     end

     context "without auth" do
       setup do
         put :update, :id => @parser.id, :parser => @parser_params
       end

       should respond_with 401
     end
     
      context "with valid params" do
        setup do
          stub_authentication
          put :update, :id => @parser.id, :parser => @parser_params
        end

        should_not_change ('The number of parsers') { Parser.count }
        should_change("parser description", :to => "New Description") { @parser.reload.description }
        should_change("parser result_model", :to => "Committee") { @parser.reload.result_model }
        should_change("parser item_parser", :to => "foo=\"new_bar\"") { @parser.reload.item_parser }
        should_change("parser attribute_parser", :to => {:newfoo => "barbar"}) { @parser.reload.attribute_parser }
        should assign_to :parser
        should redirect_to( "the show page for parser") { parser_path(assigns(:parser)) }
        should set_the_flash.to "Successfully updated parser"

      end

      context "with invalid params" do
        setup do
          stub_authentication
          put :update, :id => @parser.id, :parser => {:result_model => ""}
        end

        should_not_change ('The number of parsers') { Parser.count }
        should_not_change ('The result_model') { @parser.reload.result_model }
        should assign_to :parser
        should render_template :edit
        should set_the_flash.to /Problem/
      end

      context "for CsvParser" do
        setup do
          stub_authentication
          @new_csv_parser_params = {:result_model => "Committee",
                                    :attribute_mapping_object => [{:attrib_name => "new_foo", :column_name => "new_bar"}]}
          put :update, :id => @csv_parser.id, :csv_parser => @new_csv_parser_params
        end

        should_not_change ('The number of parsers') { Parser.count }
        
        should 'update parser' do
          assert_equal "new_bar", @csv_parser.reload.attribute_mapping[:new_foo]
        end

        should assign_to :parser
        should redirect_to( "the show page for parser") { parser_path(assigns(:parser)) }
        should set_the_flash.to "Successfully updated parser"

      end

  end  
  
end
