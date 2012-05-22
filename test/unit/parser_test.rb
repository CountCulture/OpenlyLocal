require File.expand_path('../../test_helper', __FILE__)

class ParserTest < ActiveSupport::TestCase
  
  context "The Parser class" do
    should belong_to :portal_system
    should validate_presence_of :result_model
    should validate_presence_of :scraper_type
    should_allow_values_for :result_model, "Member", "Committee", "Meeting", "Ward"
    should_not_allow_values_for :result_model, "foo", "User"
    should_allow_values_for :scraper_type, "InfoScraper", "ItemScraper"
    should_not_allow_values_for :scraper_type, "foo", "OtherScraper"
    should have_db_column :path
    
    should "serialize attribute_parser" do
      parser = Parser.create!(:description => "description of parser", :item_parser => "foo", :scraper_type => "ItemScraper", :attribute_parser => {:foo => "\"bar\"", :foo2 => "nil"}, :result_model => "Member")
      assert_equal({:foo => "\"bar\"", :foo2 => "nil"}, parser.reload.attribute_parser)
    end
    
    should have_many :scrapers
    
    should "destroy associated scrapers when parser is destroyed" do
      scraper = Factory(:scraper)
      parser = scraper.parser
      parser.destroy
      assert !Scraper.exists?(scraper.id)
    end
    
  end
  
  context "A Parser instance" do
    setup do
      PortalSystem.delete_all # some reason not getting rid of old records -- poss 2.3.2 bug (see Caboose blog)
      @parser = Factory(:parser)
      @parser.item_parser.taint # as it's been submitted by form rails will have tainted it
    end
    
    context "in general" do
      should "have results accessor" do
        @parser.instance_variable_set(:@results, "foo")
        assert_equal "foo", @parser.results
      end
      
      should "return details as title" do
        assert_equal "TestScrapedModel item parser for single scraper only", @parser.title
      end
      
      should "return details as title when new parser" do
        assert_equal "Committee item parser for single scraper only", Parser.new(:result_model => "Committee", :scraper_type => "ItemScraper").title
      end
      
      should "include description in brackets" do
        @parser.description = 'some description'
        assert_equal "TestScrapedModel item parser for single scraper only (some description)", @parser.title
      end
    end
    
    context "that is associated with portal system" do
      setup do
        @portal_system_for_parser = Factory(:portal_system, :name => "Portal for Parser")
        @parser.update_attribute(:portal_system_id, @portal_system_for_parser.id)
      end

      should "return details of portal_system in title" do
        assert_equal "TestScrapedModel item parser for Portal for Parser", @parser.title
      end
    end
        
    context "with attribute_parser has attribute_parser_object which" do
      setup do
        @attribute_parser_object = @parser.attribute_parser_object
      end
      
      should "be an Array" do
        assert_kind_of Array, @attribute_parser_object
      end
      
      should "be same size as attribute_parser" do
        assert_equal @parser.attribute_parser.keys.size, @attribute_parser_object.size
      end
      
      context "has elements which" do
        setup do
          @first_attrib = @attribute_parser_object.first
        end

        should "are AttribObjects" do
          assert_kind_of AttribObject, @first_attrib
        end
        
        should "make attribute_parser_key accessible as attrib_name" do
          assert_equal "foo", @first_attrib.attrib_name
        end

        should "make attribute_parser_value accessible as parsing_code" do
          assert_equal "\"bar\"", @first_attrib.parsing_code
        end
      end
      
      context "when attribute_parser is blank" do
        setup do
          @empty_attribute_parser_object = Parser.new.attribute_parser_object
        end

        should "be an Array" do
          assert_kind_of Array, @empty_attribute_parser_object
        end

        should "with one element" do
          assert_equal 1, @empty_attribute_parser_object.size
        end
        
        should "is an empty Struct" do
          assert_kind_of AttribObject, @empty_attribute_parser_object.first
        end
      end
      
    end
    
    context "when given attribute_parser info from form params" do
      
      should "convert to attribute_parser hash" do
        @parser.attribute_parser_object = [{ "attrib_name" => "title",
                                             "parsing_code" => "parsing code for title"},
                                           { "attrib_name" => "description",
                                             "parsing_code" => "parsing code for description"}]
        assert_equal({ :title => "parsing code for title", :description => "parsing code for description" }, @parser.attribute_parser)
      end
      
      should "set attribute_parser to empty hash if no form_params" do
        @parser.attribute_parser_object = []
        assert_equal({}, @parser.attribute_parser)
      end
    end
 
    context "when evaluating parsing code" do
      should "evaluate code" do
        assert_equal "bar", @parser.send(:eval_parsing_code, code_to_parse("foo='bar'"))
      end
      
      should "raise excaption if problem evaluating code" do
        assert_raise(NameError) { @parser.send(:eval_parsing_code, code_to_parse("foo")) }
      end
      
      should "make given object available as 'item' local variable" do
        given_obj = stub
        assert_nothing_raised(Exception) { @parser.send(:eval_parsing_code, code_to_parse, given_obj) } # will raise exception unless item local variable exists
      end
      
      should "not raise exception if duped item is changed by code" do
        given_obj = "hello world"
        assert_nothing_raised(Exception) { @parser.send(:eval_parsing_code, code_to_parse("item.to_sym"), given_obj) } 
      end
      
      should "make current_scraper base_url available as 'base_url' local variable" do
        scraper = stub(:base_url => "http://base.url")
        @parser.instance_variable_set(:@current_scraper, scraper)
        assert_equal "http://base.url", @parser.send(:eval_parsing_code, "base_url") # will raise exception unless base_url local variable exists
      end
    end
    
    context "when processing" do
            
      context "in general" do
        setup do
          @dummy_hpricot = stub_everything
          @parser.stubs(:eval_parsing_code)
        end

        should "return self" do
          assert_equal @parser, @parser.process(@dummy_hpricot)
        end
        
        should "save given scraper in instance variable" do
          scraper = stub
          assert_equal scraper, @parser.process(@dummy_hpricot, scraper).instance_variable_get(:@current_scraper)
        end

        should "eval item_parser code on hpricot doc" do
          @parser.expects(:eval_parsing_code).with('foo="bar"', @dummy_hpricot )
          @parser.process(@dummy_hpricot)
        end
        
        should "eval attribute_parser code on hpricot doc if no item_parser" do
          no_item_parser_parser = Factory.build(:parser, :item_parser => nil)
          dummy_hpricot = mock
          no_item_parser_parser.expects(:eval_parsing_code).with(){ |code, item| (code =~ /bar/) && (item == dummy_hpricot) }.at_least_once
          no_item_parser_parser.process(dummy_hpricot)
        end
        
        should "wipe existing errors" do
          @parser.errors.add_to_base("foo error")
          @parser.process(@dummy_hpricot)
          assert_nil @parser.errors[:base]
        end
      end
      
      
      context "and single item is returned" do
        setup do
          @dummy_item = stub
          @dummy_hpricot = stub
          @parser.stubs(:eval_parsing_code).with(@parser.item_parser, @dummy_hpricot).returns(@dummy_item)
        end
      
        should "evaluate each attribute_parser on item" do
          @parser.expects(:eval_parsing_code).twice.with(){ |code, item| (code =~ /bar/)&&(item == @dummy_item) }
          @parser.process(@dummy_hpricot)
        end
        
        should "store result of attribute_parser as hash using attribute_parser keys" do
          @parser.expects(:eval_parsing_code).twice.with(){ |code, item| (code =~ /bar/)&&(item == @dummy_item) }.returns("some value")
          assert_equal ([{:foo => "some value", :foo1 => "some value"}]), @parser.process(@dummy_hpricot).results
        end
        
        should "strip leading and trailing spaces" do
          @parser.expects(:eval_parsing_code).twice.with(){ |code, item| (code =~ /bar/)&&(item == @dummy_item) }.returns("   \n   some value \n  \n")
          assert_equal ([{:foo => "some value", :foo1 => "some value"}]), @parser.process(@dummy_hpricot).results
        end
      end
            
      context "and array of items is returned" do
        setup do
          @dummy_item_1, @dummy_item_2 = stub, stub
          @dummy_hpricot = stub
          @parser.stubs(:eval_parsing_code).with(@parser.item_parser, @dummy_hpricot).returns([@dummy_item_1, @dummy_item_2])
        end
      
        should "evaluate each attribute_parser value on item" do
          @parser.expects(:eval_parsing_code).twice.with(){ |code, item| (code =~ /bar/)&&(item == @dummy_item_1) }
          @parser.expects(:eval_parsing_code).twice.with(){ |code, item| (code =~ /bar/)&&(item == @dummy_item_2) }
          @parser.process(@dummy_hpricot)
        end
        
        should "store result of attribute_parser as hash using attribute_parser keys" do
          @parser.stubs(:eval_parsing_code).with(){ |code, item| (code =~ /bar/)&&(item == @dummy_item_1) }.returns("some value")
          @parser.stubs(:eval_parsing_code).with(){ |code, item| (code =~ /bar/)&&(item == @dummy_item_2) }.returns("another value")
          assert_equal ([{ :foo => "some value", :foo1 => "some value" },
                         { :foo => "another value", :foo1 => "another value" }]), @parser.process(@dummy_hpricot).results
        end
        
        should "strip leading and trailing spaces" do
          @parser.stubs(:eval_parsing_code).with(){ |code, item| (code =~ /bar/)&&(item == @dummy_item_1) }.returns("some value")
          @parser.stubs(:eval_parsing_code).with(){ |code, item| (code =~ /bar/)&&(item == @dummy_item_2) }.returns("   \n   another value \n  \n")
          assert_equal ([{ :foo => "some value", :foo1 => "some value" },
                         { :foo => "another value", :foo1 => "another value" }]), @parser.process(@dummy_hpricot).results
        end
      end
      
      # regression test      
      context "and Nokogiri node set is returned" do
        setup do
          node_set = Nokogiri.HTML('<li>baz1</li><li>baz2</li>').search('li')
          @dummy_nokogiri = stub
          @parser.expects(:eval_parsing_code).with(@parser.item_parser, @dummy_nokogiri).returns(node_set)
        end
      
        should "evaluate each node item" do
          @parser.expects(:eval_parsing_code).twice.with(){ |code, item| (item.to_s =~ /baz1/)  }
          @parser.expects(:eval_parsing_code).twice.with(){ |code, item| (item.to_s =~ /baz2/)  }
          @parser.process(@dummy_nokogiri)
        end        
      end

      context "and array of items returned includes nil" do
        setup do
          @dummy_item_1 = stub
          @dummy_hpricot = stub
          @parser.stubs(:eval_parsing_code).with(@parser.item_parser, @dummy_hpricot).returns([@dummy_item_1, nil])
        end
      
        should "evaluate each attribute_parser on non-nil items only" do
          @parser.stubs(:eval_parsing_code).with(){ |code, item| item == @dummy_item_1 }
          @parser.expects(:eval_parsing_code).never.with(){ |code, item| (code == "\"bar1\"")&&item.nil? }
          assert @parser.process(@dummy_hpricot).errors.empty? # failing expectation will raise exception, which will get caught and added to errors. Maybe move functionality into own method, but for the moment this works
        end
        
        should "return no results for nil item" do
          @parser.stubs(:eval_parsing_code).with(anything, @dummy_item_1).returns("some value")
           assert_equal ([{ :foo => "some value", :foo1 => "some value" }]), @parser.process(@dummy_hpricot).results
        end
        
      end
            
      context "and problems occur when parsing items" do
        setup do
          @dummy_hpricot_for_problem_parser = Hpricot("some text")
          @problem_parser = Parser.new(:item_parser => "foo + bar")
          @problem_parser.instance_eval("@results='foo'") # doesn't like instance_variable_set
        end
      
        should "not raise exception" do
          assert_nothing_raised() { @problem_parser.process(@dummy_hpricot_for_problem_parser) }
        end
        
        should "return self" do
          assert_equal @problem_parser, @problem_parser.process(@dummy_hpricot_for_problem_parser)
        end
        
        should "store errors in parser" do
          errors = @problem_parser.process(@dummy_hpricot_for_problem_parser).errors[:base]
          assert_match /Exception raised.+parsing items/, errors
          assert_match /Problem .+parsing code.+foo \+ bar/m, errors
          assert_match /Hpricot.+#{@dummy_hpricot_for_problem_parser.inspect}/m, errors
        end
        
        should "wipe previous results variable" do
          assert_nil @problem_parser.process(@dummy_hpricot_for_problem_parser).results
        end
        
      end
      
      context "and problems occur when parsing attributes" do
        setup do
          @dummy_item_1, @dummy_item_2 = "String_1", "String_2"
          @dummy_hpricot_for_attrib_prob = stub
          @problem_parser = Parser.new(:item_parser => "'some string... here'", :attribute_parser => {:full_name => 'foobar + (1..2)'}) # => unknown local variable
        end
      
        should "not raise exception" do
          assert_nothing_raised() { @problem_parser.process(@dummy_hpricot_for_attrib_prob) }
        end
        
        should "return self" do
          assert_equal @problem_parser, @problem_parser.process(@dummy_hpricot_for_attrib_prob)
        end
        
        should "store errors in parser" do
          errors = @problem_parser.process(@dummy_hpricot_for_attrib_prob).errors[:base]
          assert_match /Exception raised.+parsing attributes/, errors
          assert_match /Problem .+parsing code.+foobar/m, errors
          assert_match /undefined local variable or method.+foobar/m, errors
        end
        
        should "separate consecutive points in parsing code when storing errors in parser" do
          # This is because of bug in Rails when displaying errors with consecutive points
          errors = @problem_parser.process(@dummy_hpricot_for_attrib_prob).errors[:base]
          assert_match /Problem .+parsing code.+foobar \+ \(1\. \.2\)/m, errors
        end
        
        should "separate consecutive points in item to be parsed when storing errors in parser" do
          # This is because of bug in Rails when displaying errors with consecutive points
          errors = @problem_parser.process(@dummy_hpricot_for_attrib_prob).errors[:base]
          assert_match /Problem .+parsing.+on following.+some string\. \. \. here/m, errors
        end
      end
    end 

    context "when returning bitwise_flag" do

      should "return nil if attribute_parser nil" do
        @parser.attribute_parser = nil
        assert_nil @parser.bitwise_flag
      end

      should "return nil if attribute_parser non-nil but no bitwise_flag key" do
        assert_nil @parser.bitwise_flag
      end

      should "return bitwise_flag as integer set in attribute_parser" do
        @parser.attribute_parser = {:foo => 'bar', :bitwise_flag => '4'}
        assert_equal 4, @parser.bitwise_flag
      end
    end
  end
  

  private
  def dummy_response(response_name)
    IO.read(File.join([RAILS_ROOT + "/test/fixtures/dummy_responses/#{response_name.to_s}.html"]))
  end
  
  def code_to_parse(some_code="item")
    some_code.taint
  end
end
