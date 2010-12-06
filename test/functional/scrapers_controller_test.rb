require 'test_helper'

class ScrapersControllerTest < ActionController::TestCase
  
  # index test
  context "on GET to :index without auth" do
    setup do
      Factory(:scraper)
      get :index
    end
  
    should respond_with 401
  end
  
  context "on GET to :index" do
    setup do
      stub_authentication
      @council1 = Factory(:council)
      @scraper1 = Factory(:scraper, :council => @council1)
      @portal_system = Factory(:portal_system)
      @council2 = Factory(:another_council, :portal_system => @portal_system)
      @scraper2 = Factory(:info_scraper, :council => @council2)
      @council3 = Factory(:council, :name => "NoScraper Council")
      get :index
    end
  
    should assign_to( :councils_with_scrapers) { [@council2, @council1 ] }
    should assign_to( :councils_without_scrapers) { [@council3] }
    should respond_with :success
    should render_template :index
    should_not set_the_flash
    
    should "list all councils with scrapers" do
      assert_select "#councils #with_scrapers" do
        assert_select ".council", 2 do
          assert_select "h3 a", @scraper1.council.name
        end
      end
    end
    
    should "list all councils without scrapers" do
      assert_select "#councils #without_scrapers" do
        assert_select ".council", 1 do
          assert_select "h4 a", @council3.name
        end
      end
    end
    
    should "show title" do
      assert_select "title", /All scrapers/
    end
    
    should "list scrapers for each council" do
      assert_select "#council_#{@scraper1.council.id}" do
        assert_select "li a", @scraper1.title
      end
    end
    
    should "link to portal system if council has portal system" do
      assert_select "#council_#{@scraper2.council.id}" do
        assert_select "a", @portal_system.name
      end
    end
    
    should "not show share block" do
      assert_select "#share_block", false
    end
  end
  
  # show test
  context "on GET to :show for scraper without auth" do
    setup do
      @scraper = Factory(:scraper)
      get :show, :id => @scraper.id
    end
  
    should respond_with 401
  end
  
  context "on GET to :show for scraper" do
    setup do
      @scraper = Factory(:scraper)
      @scraper.class.any_instance.expects(:process).never
      @scraper1 = Factory(:info_scraper, :council => @scraper.council)
      stub_authentication
      get :show, :id => @scraper.id
    end
  
    should assign_to :scraper
    should respond_with :success
    should render_template :show
    
    should "show scraper title in page title" do
      assert_select "title", /#{@scraper.title}/
    end
    
    should "show link to perform dry run" do
      assert_select "#scraper .button-to input[value*=?]", /test scrape/
    end
  
    should "show link to perform edit" do
      assert_select "#scraper a", /edit/
    end
    
    should "show links to council's other scrapers" do
      assert_select "#other_scrapers" do
        assert_select "li a", :text => @scraper.title, :count => 0
        assert_select "li a", :text => @scraper1.title
      end
    end
    
    should "not show share block" do
      assert_select "#share_block", false
    end
  end
  
  context "on GET to :show with CSV parser" do
    setup do
      @csv_parser = Factory(:csv_parser)
      @scraper = Factory(:scraper, :parser => @csv_parser)
      stub_authentication
      get :show, :id => @scraper.id
    end
  
    should assign_to :scraper
    should respond_with :success
    should render_template :show
    
    should "show details of parser" do
      assert_select "title", /#{@scraper.title}/
    end
    
  end
  
  context "on POST to :scrape with :dry_run" do
    setup do
      @scraper = Factory(:scraper)
    end
      
    should "process scraper" do
      @scraper.class.any_instance.expects(:process).returns(stub_everything)
      stub_authentication
      post :scrape, :id => @scraper.id, :dry_run => true
    end
  end
  
  context "on GET to :show with :dry_run of CsvScraper" do
    setup do
      @scraper = Factory(:csv_scraper)
    end
      
    should "process scraper" do
      @scraper.class.any_instance.expects(:process).returns(stub_everything)
      stub_authentication
      post :scrape, :id => @scraper.id, :dry_run => true
    end
  end
  
  context "on POST to :scrape with successful :dry_run" do
    setup do
      @scraper = Factory(:scraper)
      @scraper.parser.update_attribute(:result_model, 'Member') # update to use members, as TestScrapedModel cause probs with link_for
      @member = Factory(:member, :council => @scraper.council)
      @member.save # otherwise looks like new_before_save
      @new_member = Member.new(:full_name => "Fred Flintstone", :uid => 55)
      @scraper.class.any_instance.stubs(:process).returns(@scraper)
      @scraper.stubs(:results).returns([ScrapedObjectResult.new(@member), ScrapedObjectResult.new(@new_member)])
      stub_authentication
      post :scrape, :id => @scraper.id, :dry_run => true
    end
  
    should assign_to(:scraper)
    should assign_to(:results)
    should respond_with :success
    
    should "show summary of successful results" do
      assert_select "#results" do
        assert_select "div.member", 2 do
          assert_select "h4", /#{@member.full_name}/
          assert_select "div.new", 1 do
            assert_select "h4", /Fred Flintstone/
          end
        end
      end
    end
  
    should "not show summary of problems" do
      puts css_select "div.errorExplanation"
      assert_select "div.errorExplanation", false
    end
  end
  
  context "on POST to :scrape with successful :dry_run of csv_scraper" do
    setup do
      @scraper = Factory(:csv_scraper)
  
      @scraper.parser.update_attribute(:result_model, 'FinancialTransaction')
  
      @csv_rawdata = dummy_csv_data('supplier_payments')
      CsvScraper.any_instance.expects(:_data).returns(@csv_rawdata)
      # @member = Factory(:member, :council => @scraper.council)
      # @member.save # otherwise looks like new_before_save
      # @new_member = Member.new(:full_name => "Fred Flintstone", :uid => 55)
      # @scraper.class.any_instance.stubs(:scrape).returns(@scraper)
      # @scraper.stubs(:results).returns([ScrapedObjectResult.new(@member), ScrapedObjectResult.new(@new_member)])
      stub_authentication
      # pp @scraper.parser
      post :scrape, :id => @scraper.id, :dry_run => true
    end
  
    should assign_to(:scraper)
    should assign_to(:results)
    should respond_with :success
    
    should "show summary of successful results" do
      assert_select "#results" do
        # assert_select "div.member", 2 do
          # assert_select "h4", /#{@member.full_name}/
          # assert_select "div.new", 1 do
            # assert_select "h4", /Fred Flintstone/
          # end
        # end
      end
    end
  
    should "not show summary of problems" do
      assert_select "div.errorExplanation", false
    end
  end
  
  context "on POST to :scrape with :dry_run with request error" do
    setup do
      @scraper = Factory(:scraper)
      @scraper.class.any_instance.stubs(:_data).raises(Scraper::RequestError, "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found")
      parser = @scraper.parser
      stub_authentication
      post :scrape, :id => @scraper.id, :dry_run => true
    end
    
    should assign_to :scraper
    should respond_with :success
    
    should "show summary of problems" do
      assert_select "div.errorExplanation" do
        assert_select "li", /Problem getting data/
      end
    end
  end
  
  context "on GET to :show with :dry_run with parsing problems" do
    setup do
      @scraper = Factory(:scraper)
      @scraper.class.any_instance.stubs(:_data).returns(stub_everything)
      @scraper.parser.update_attribute(:item_parser, "foo")
      Parser.any_instance.stubs(:results) # pretend there are no results
      stub_authentication
      post :scrape, :id => @scraper.id, :dry_run => true
    end
    
    should assign_to :scraper
    should assign_to :results
    should respond_with :success
    
    should "show summary of problems" do
      assert_select "div.errorExplanation" do
        assert_select "li", /Exception raised parsing items/
      end
    end
  end
  
  context "POST to :scrape" do
    setup do
      @scraper = Factory(:scraper)
      stub_authentication
    end
      
    should "add to delayed job queue" do
      Delayed::Job.expects(:enqueue).with(instance_of(ItemScraper))
      post :scrape, :id => @scraper.id
    end
    
    should "set the flash to show success" do
      post :scrape, :id => @scraper.id
      assert_match /being processed/, flash[:notice]
    end
     
  end
  
  context "POST to :scrape when processing immediately" do
    setup do
      @scraper = Factory(:scraper)
    end
      
    should "process scraper" do
      @scraper.class.any_instance.expects(:process).with(:save_results => true).returns(stub_everything)
      stub_authentication
      post :scrape, :id => @scraper.id, :process => "immediately"
    end
  end
  
  context "on POST to :scraper with successful process immediately" do
    setup do
      @scraper = Factory(:scraper)
      @scraper.parser.update_attribute(:result_model, 'Member') # update to use members, as TestScrapedModel cause probs with link_for
      @scraper.class.any_instance.stubs(:_data).returns(stub_everything)
      @scraper.class.any_instance.stubs(:parsing_results).returns([{ :full_name => "Fred Flintstone", :uid => 1, :url => "http://www.anytown.gov.uk/members/fred" }] )
      stub_authentication
      post :scrape, :id => @scraper.id, :process => "immediately"
    end
  
    should assign_to :scraper
    should assign_to :results
    should assign_to :results_summary
    should respond_with :success
    should_change("The number of members", :by => 1) { Member.count }
    
    should "show summary of successful results" do
      assert_select "#results_summary" do
        assert_select "p", /1 new/
      end
    end
    
    should "show results" do
      assert_select "#results" do
        assert_select "div.member" do
          assert_select "h4 a", /Fred Flintstone/
        end
      end
    end
  
    should "not show summary of problems" do
      puts css_select("div.errorExplanation")
      assert_select "div.errorExplanation", false
    end
  end
  
  context "on GET to :show with unsuccesful :scrape immediately due to failed validation" do
    setup do
      @scraper = Factory(:scraper)
      @scraper.parser.update_attribute(:result_model, 'Member') # update to use members, as TestScrapedModel cause probs with link_for
      @scraper.class.any_instance.stubs(:_data).returns(stub_everything)
      @scraper.class.any_instance.stubs(:parsing_results).returns([{ :full_name => "Fred Flintstone", :uid => 1, :url => "http://www.anytown.gov.uk/members/fred" },
                                                            { :full_name => "Bob Nourl"}] )
      stub_authentication
      post :scrape, :id => @scraper.id, :process => "immediately"
    end
    
    should assign_to(:scraper)
    should assign_to(:results)
    # should_change("The number of members", :by => 1) { Member.count }# => Not two
    should respond_with :success
    should "show summary of problems" do
      assert_select "div.member div.errorExplanation" do
        assert_select "li", "Url can't be blank"
      end
    end
    should "highlight member with error" do
      assert_select "div.member", :count => 2 do
        assert_select "div.errors", :count => 1 do # only one of which has error class
          assert_select "div.member div.errorExplanation" #...and that has error explanation in it
        end
     end
   end
  end
  
  # new test
  context "on GET to :new without auth" do
    setup do
      @council = Factory(:council)
      get :new, :type  => "InfoScraper", :council_id => @council.id
    end
  
    should respond_with 401
  end
  
  context "on GET to :new with no scraper type given" do
    should "raise exception" do
      stub_authentication
      assert_raise(ArgumentError) { get :new }
    end
  end
  
  context "on GET to :new with bad scraper type" do
    should "raise exception" do
      stub_authentication
      assert_raise(ArgumentError) { get :new, :type  => "Member" }
    end
  end
  
  context "on GET to :new" do
    setup do
      @council = Factory(:council)
    end
  
    context "for basic scraper" do
      setup do
        stub_authentication
        get :new, :type  => "InfoScraper", :council_id => @council.id
      end
  
      should assign_to :scraper
      should respond_with :success
      should render_template :new
      should_not set_the_flash
  
      should "assign given type of scraper" do
        assert_kind_of InfoScraper, assigns(:scraper)
      end
    
      should "build parser from params" do
        assert assigns(:scraper).parser.new_record?
        assert_equal "InfoScraper", assigns(:scraper).parser.scraper_type
      end
      
      should "show nested form for parser" do
        assert_select "textarea#scraper_parser_attributes_item_parser"
        assert_select "input#scraper_parser_attributes_attribute_parser_object__attrib_name"
        assert_select "input#scraper_parser_attributes_attribute_parser_object__parsing_code"
      end
  
      should "include scraper type in hidden field" do
        assert_select "input#type[type=hidden][value=InfoScraper]"
      end
      
      should "include council in hidden field" do
        assert_select "input#scraper_council_id[type=hidden][value=#{@council.id}]"
      end
      
      should "not show select box for possible_parsers" do
        assert_select "select#scraper_parser_id", false
      end
      
      should "not show related_model select_box for info scraper" do
        assert_select "select#scraper_parser_attributes_related_model", false
      end
      
      should "not have hidden parser details form" do
        assert_select "fieldset#parser_details[style='display:none']", false
      end
      
      should "not have link to show parser form" do
        assert_select "form a", :text => /use dedicated parser/i, :count => 0
      end
  
      should "show hidden field with parser scraper_type" do
        assert_select "input#scraper_parser_attributes_scraper_type[type=hidden][value=InfoScraper]"
      end
      
    end
    
    context "on GET to :new with no given council" do
      setup do
        stub_authentication
        get :new, :type  => "InfoScraper"
      end
  
      should assign_to :scraper 
      should respond_with :success
      
      should 'show select box for council' do
        assert_select "select#scraper_council_id"
      end
    end
  
    context "for basic scraper with given result model" do
      setup do
        Factory(:parser, :result_model => "Committee", :scraper_type => "InfoScraper") # make sure there's at least one parser already in db with this result model
        stub_authentication
        get :new, :type  => "InfoScraper", :council_id => @council.id, :result_model => "Committee"
      end
  
      should "build parser from params" do
        assert assigns(:scraper).parser.new_record?
        assert_equal "Committee", assigns(:scraper).result_model
        assert_equal "InfoScraper", assigns(:scraper).parser.scraper_type
      end
  
      should "show result_model select box in form" do
        assert_select "select#scraper_parser_attributes_result_model" do
          assert_select "option[value='Committee'][selected='selected']"
        end
      end
    end
    
    context "for basic item_scraper" do
      setup do
        stub_authentication
        get :new, :type  => "ItemScraper", :council_id => @council.id
      end
  
      should assign_to :scraper
      should respond_with :success
      should render_template :new
      should_not set_the_flash
  
      should "assign given type of scraper" do
        assert_kind_of ItemScraper, assigns(:scraper)
        assert assigns(:scraper).new_record?
      end
      
      should "not show related_model select_box for info scraper" do
        assert_select "select#scraper_parser_attributes_related_model"
      end
    end
    
    context "when scraper council has portal system" do
      setup do
        @portal_system = Factory(:portal_system, :name => "Some Portal for Councils")
        @portal_system.parsers << @parser = Factory(:another_parser) # add a parser to portal_system...
        @council.update_attribute(:portal_system_id, @portal_system.id)# .. and associate portal_system to council
        @parser = Factory(:parser, :portal_system => @portal_system)
        stub_authentication
        get :new, :type  => "ItemScraper", :result_model => @parser.result_model, :council_id => @council.id
      end
    
      should assign_to :scraper 
      should respond_with :success
      should render_template :new
      should_not set_the_flash
      
      should "assign appropriate parser to scraper" do
        assert_equal @parser, assigns(:scraper).parser
      end
      
      should "show text box for url" do
        assert_select "input#scraper_url"
      end
  
      should "show hidden field with parser details" do
        assert_select "input#scraper_parser_id[type=hidden][value=#{@parser.id}]"
      end
      
      should "not show parser_details form" do
        assert_select "fieldset#parser_details", false
      end
      
      should "show parser details" do
        assert_select "div#parser_#{@parser.id}"
      end
      
      should "have link to show parser form" do
        assert_select "form a", /use dedicated parser/i
      end
    end
    
    context "when scraper council has portal system but dedicated parser specified" do
      setup do
        @portal_system = Factory(:portal_system, :name => "Some Portal for Councils")
        @portal_system.parsers << @parser = Factory(:another_parser) # add a parser to portal_system...
        @council.update_attribute(:portal_system_id, @portal_system.id)# .. and associate portal_system to council
        @parser = Factory(:parser, :portal_system => @portal_system)
        stub_authentication
        get :new, :type  => "ItemScraper", :result_model => @parser.result_model, :council_id => @council.id, :dedicated_parser => true
      end
    
      should assign_to :scraper 
      should respond_with :success
      should render_template :new
      should_not set_the_flash
      
      should "assign appropriate parser to scraper" do
        assert_equal @parser, assigns(:scraper).parser
      end
      
      should "show text box for url" do
        assert_select "input#scraper_url"
      end
  
      should "show parser_details form" do
        assert_select "fieldset#parser_details"
      end
      
      should "show not show hidden field with parser details" do
        assert_select "input#scraper_parser_id[type=hidden][value=#{@parser.id}]", false
      end
      
      should "show link to user existing parser for portal_system" do
        assert_select "form p.alert a", /use existing parser/i
      end
    end
    
    context "when scraper council has portal system but parser does not exist" do
      setup do
        @portal_system = Factory(:portal_system, :name => "Some Portal for Councils")
        @portal_system.parsers << @parser = Factory(:another_parser) # add a parser to portal_system...
        @council.update_attribute(:portal_system_id, @portal_system.id)# .. and associate portal_system to council
        @parser = Factory(:parser, :portal_system => @portal_system)
        stub_authentication
        get :new, :type  => "ItemScraper", :result_model => "Meeting", :council_id => @council.id
      end
    
      should assign_to :scraper 
      should respond_with :success
      should render_template :new
      should_not set_the_flash
      
      should "assign appropriate fresh parser to scraper" do
        assert assigns(:scraper).parser.new_record?
      end
      
      should "show text box for url" do
        assert_select "input#scraper_url"
      end
  
      should "show parser details form" do
        assert_select "fieldset#parser_details"
      end
      
      should "show link to add new parser for portal_system" do
        assert_select "form p.alert", /no parser/i do
          assert_select "a", /add new/i
        end
      end
    end
    
    context "for CsvScraper" do
      setup do
        stub_authentication
        get :new, :type  => "CsvScraper", :council_id => @council.id
      end
  
      should assign_to :scraper
      should respond_with :success
      should render_template :new
      should_not set_the_flash
  
      should "assign given type of scraper" do
        assert_kind_of CsvScraper, assigns(:scraper)
      end
    
      should "build parser from params" do
        assert assigns(:scraper).parser.new_record?
        assert_equal "CsvScraper", assigns(:scraper).parser.scraper_type
      end
      
      should "show nested form for csv_parser" do
        assert_select "input#scraper_parser_attributes_attribute_mapping_object__attrib_name"
        assert_select "input#scraper_parser_attributes_attribute_mapping_object__column_name"
      end
  
      should "include scraper type in hidden field" do
        assert_select "input#type[type=hidden][value=CsvScraper]"
      end
      
    end
  
    context "for CsvScraper with existing parser id" do
      setup do
        @portal_system = Factory(:portal_system)
        @csv_parser = Factory(:csv_parser, :portal_system => @portal_system)
        stub_authentication
        get :new, :type  => "CsvScraper", :parser_id  => @csv_parser.id, :council_id => @council.id
      end
  
      should assign_to :scraper
      should respond_with :success
      should render_template :new
      should_not set_the_flash
  
      should "assign given type of scraper" do
        assert_kind_of CsvScraper, assigns(:scraper)
      end
    
      should "assign parser" do
        assert_equal @csv_parser, assigns(:scraper).parser
      end
      
      should "show hidden field with parser details" do
        assert_select "input#scraper_parser_id[type=hidden][value=#{@csv_parser.id}]"
      end
      
      should "not show parser_details form" do
        assert_select "fieldset#parser_details", false
      end
      
      should "show parser details" do
        assert_select "div#csv_parser_#{@csv_parser.id}"
      end
      
      should "have link to show parser form" do
        assert_select "form a", /use dedicated parser/i
      end
  
      should "show nested form for csv_parser" do
        assert_select "input#scraper_parser_attributes_attribute_mapping_object__attrib_name"
        assert_select "input#scraper_parser_attributes_attribute_mapping_object__column_name"
      end
  
    end
  
  end
  
  # create tests
  
  context "on POST to :create" do
    setup do
      @council = Factory(:council)
      @portal_system = Factory(:portal_system, :name => "Another portal system")
      @existing_parser = Factory(:parser, :portal_system => @portal_system, :description => "existing parser")
      
      @scraper_params = { :council_id => @council.id, 
                          :url => "http://anytown.com/committees", 
                          :parser_attributes => { :description => "new parser", 
                                                  :result_model => "Committee", 
                                                  :scraper_type => "InfoScraper", 
                                                  :item_parser => "some code",
                                                  :attribute_parser_object => [{:attrib_name => "foo", :parsing_code => "bar"}] }}
      @exist_scraper_params = { :council_id => @council.id, 
                                :url => "http://anytown.com/committees", 
                                :parser_id => @existing_parser.id }
    end
    
    context "without auth" do
      setup do
        post :create, { :type => "InfoScraper", :scraper => @scraper_params }
      end
  
      should respond_with 401
    end
    
    context "with no scraper type given" do
      should "raise exception" do
        stub_authentication
        assert_raise(ArgumentError) { post :create, { :scraper => @scraper_params } }
      end
    end
    
    context "with bad scraper type" do
      should "raise exception" do
        stub_authentication
        assert_raise(ArgumentError) { get :create, { :type  => "Member", :scraper => @scraper_params } }
      end
    end
    
    context "with scraper type" do
      
      context "and new parser" do
        setup do
          stub_authentication
          post :create, { :type => "InfoScraper", :scraper => @scraper_params }
        end
      
        should_change('The number of scrapers', :by => 1) { Scraper.count }
        should assign_to :scraper
        should redirect_to( "the show page for scraper") { scraper_path(assigns(:scraper)) }
        should set_the_flash.to "Successfully created scraper"
      
        should "save as given scraper type" do
          assert_kind_of InfoScraper, assigns(:scraper)
        end
      
        should_change('The number of parsers', :by => 1) { Parser.count }
      
        should "save parser description" do
          assert_equal "new parser", assigns(:scraper).parser.description
        end
      
        should "save parser item_parser" do
          assert_equal "some code", assigns(:scraper).parser.item_parser
        end
      
        should "save parser attribute_parser" do
          assert_equal({:foo => "bar"}, assigns(:scraper).parser.attribute_parser)
        end
      end
      
      context "and new csv_parser" do
        setup do
          @csv_scraper_params = { :council_id => @council.id, 
                                  :url => "http://anytown.com/committees", 
                                  :parser_attributes => { :result_model => "Committee", 
                                                          :scraper_type => "InfoScraper",
                                                          :type => 'CsvParser', 
                                                          :item_parser => "some code",
                                                          :description => "new parser", 
                                                          :attribute_mapping_object => [{"attrib_name" => "foo", "column_name" => "FooName"}] }}
          stub_authentication
          post :create, { :type => "InfoScraper", :scraper => @csv_scraper_params }
        end
      
        should_change('The number of scrapers', :by => 1) { Scraper.count }
        should assign_to :scraper
        should redirect_to( "the show page for scraper") { scraper_path(assigns(:scraper)) }
        should set_the_flash.to "Successfully created scraper"
      
        should "save as given scraper type" do
          assert_kind_of InfoScraper, assigns(:scraper)
        end
      
        should_change('The number of parsers', :by => 1) { Parser.count }
      
        should "save parser description" do
          assert_equal "new parser", assigns(:scraper).parser.description
        end
      
        should "save parser item_parser" do
          assert_equal "some code", assigns(:scraper).parser.item_parser
        end
      
        should "save parser as csv_parser" do
          assert_kind_of CsvParser, assigns(:scraper).parser
        end
      
        should "save parser attribute_parser" do
          assert_equal({:foo => "FooName"}, assigns(:scraper).parser.attribute_mapping)
        end
      end
      
      context "and existing parser" do
        setup do
          stub_authentication
          post :create, { :type => "InfoScraper", :scraper => @exist_scraper_params }
        end
      
        should_change('The number of scrapers', :by => 1) { Scraper.count }
        should assign_to :scraper
        should redirect_to( "the show page for scraper") { scraper_path(assigns(:scraper)) }
        should set_the_flash.to "Successfully created scraper"
      
        should "save as given scraper type" do
          assert_kind_of InfoScraper, assigns(:scraper)
        end
      
        should_not_change("The number of parsers") { Parser.count }
      
        should "associate existing parser to scraper " do
          assert_equal @existing_parser, assigns(:scraper).parser
        end
      
      end
      
      context "and new parser and existing parser details both given" do
        setup do
          stub_authentication
          post :create, { :type => "InfoScraper", :scraper => @scraper_params.merge(:parser_id => @existing_parser.id ) }
        end
      
        should_change('The number of scrapers', :by => 1) { Scraper.count }
        should_change('The number of parsers', :by => 1) { Parser.count }
        should assign_to :scraper
        should redirect_to( "the show page for scraper") { scraper_path(assigns(:scraper)) }
        should set_the_flash.to "Successfully created scraper"
      
        should "save parser description from new details" do
          assert_equal "new parser", assigns(:scraper).parser.description
        end
      end
            
    end
    
  end
  
  # edit tests
  context "on get to :edit a scraper without auth" do
    setup do
      @scraper = Factory(:scraper)
      get :edit, :id => @scraper.id
    end
  
    should respond_with 401
  end
  
  context "on get to :edit a scraper" do
    setup do
      @scraper = Factory(:scraper)
      stub_authentication
      get :edit, :id => @scraper.id
    end
    
    should assign_to :scraper
    should respond_with :success
    should render_template :edit
    should_not set_the_flash
    
    should "show nested form for parser " do
      assert_select "input[type=hidden][value=?]#scraper_parser_attributes_id", @scraper.parser.id
    end
    
    should "not show link to write new parser" do
      assert_select "form p.alert a", :text => /add new/i, :count => 0 
    end
  end
  
  context "on get to :edit a scraper for portal council" do
    setup do
      @scraper = Factory(:scraper)
      @council = @scraper.council
      @portal_system = Factory(:portal_system, :name => "Some Portal for Councils")
      @council.update_attribute(:portal_system_id, @portal_system.id)# .. and associate portal_system to council
      stub_authentication
      get :edit, :id => @scraper.id
    end
    
    should assign_to :scraper
    should respond_with :success
    should render_template :edit
    
    should "not show link to write new parser" do
      assert_select "form p.alert a", :text => /add new/i, :count => 0 
    end
  end
  
  # update tests
  context "on PUT to :update without auth" do
    setup do
      @scraper = Factory(:scraper)
      put :update, { :id => @scraper.id, 
                     :scraper => { :council_id => @scraper.council_id, 
                                   :result_model => "Committee", 
                                   :url => "http://anytown.com/new_committees", 
                                   :parser_attributes => { :id => @scraper.parser.id, :description => "new parsing description", :item_parser => "some code" }}}
    end
  
    should respond_with 401
  end
  
  context "on PUT to :update" do
    setup do
      @scraper = Factory(:scraper)
      stub_authentication
      put :update, { :id => @scraper.id, 
                     :scraper => { :council_id => @scraper.council_id, 
                                   :url => "http://anytown.com/new_committees", 
                                   :parser_attributes => { :id => @scraper.parser.id, :description => "new parsing description", :item_parser => "new code" }}}
  
      
      # @scraper_params = { :council_id => @council.id, 
      #                     :url => "http://anytown.com/committees", 
      #                     :parser_attributes => { :description => "new parser", 
      #                                             :result_model => "Committee", 
      #                                             :scraper_type => "InfoScraper", 
      #                                             :item_parser => "some code",
      #                                             :attribute_parser_object => [{:attrib_name => "foo", :parsing_code => "bar"}] }}
      #                              
    end
  
    should assign_to :scraper
    should redirect_to( "the show page for scraper") { scraper_path(@scraper) }
    should set_the_flash.to "Successfully updated scraper"
    
    should "update scraper" do
      assert_equal "http://anytown.com/new_committees", @scraper.reload.url
    end
    
    should "update scraper parser" do
      assert_equal "new code", @scraper.parser.reload.item_parser
      assert_equal "new parsing description", @scraper.parser.reload.description
    end
  end
  
  # delete tests
  context "on delete to :destroy a scraper without auth" do
    setup do
      @scraper = Factory(:scraper)
      delete :destroy, :id => @scraper.id
    end
  
    should respond_with 401
  end
  
  context "on delete to :destroy a scraper" do
    
    setup do
      @scraper = Factory(:scraper)
      stub_authentication
      delete :destroy, :id => @scraper.id
    end
    
    should "destroy scraper" do
      assert_nil Scraper.find_by_id(@scraper.id)
    end
    should redirect_to( "the scrapers page") { scrapers_url(:anchor => "council_#{@scraper.council_id}") }
    should set_the_flash.to( "Successfully destroyed scraper")
  end
  
end
