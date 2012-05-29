require File.expand_path('../../test_helper', __FILE__)

class GenericEntityMatcherTest < ActiveSupport::TestCase
  
  context "The GenericEntityMatcher module" do
    
    context "when returning possible matches" do

      should "return nil if nil given" do
        assert_nil GenericEntityMatcher.possible_matches
      end

      # should "match against possible_matches for given class" do
      #   Council.expects(:possible_matches).with(:title => 'foo thing')
      #   GenericEntityMatcher.possible_matches(:title => 'foo thing', :type => 'Council')
      # end
      
      context "by default" do
        setup do
          @result_1 = TestScrapedModel.create(:title => 'result 1')
          @result_2 = TestScrapedModel.create(:title => 'result 2')
          TestModelWithSpendingStat.stubs(:all).returns([@result_1, @result_2])
          
        end
        
        should "find all starting with first word of title if class doesn't implement possible matches" do
          HyperlocalSite.expects(:all).with(has_entry(:conditions => ['title LIKE ?',"foo%"]))
          GenericEntityMatcher.possible_matches(:title => 'foo thing', :type => 'HyperlocalSite')
        end

        should "find all starting with first word of name if class doesn't implement possible matches and has name rather than title attribute" do
          TestModelWithSpendingStat.expects(:all).with(has_entry(:conditions => ['name LIKE ?',"foo%"]))
          GenericEntityMatcher.possible_matches(:title => 'foo thing', :type => 'TestModelWithSpendingStat')
        end
        
        should "find all starting with first word of title if class doesn't implement possible matches and implements normalised_title" do
          TestScrapedModel.expects(:all).with(has_entry(:conditions => ['normalised_title LIKE ?',"foo%"]))
          GenericEntityMatcher.possible_matches(:title => 'The FOO Thing', :type => 'TestScrapedModel')
        end
        
        should "find all in alphabetical order of title if model has title attribute" do
          TestScrapedModel.expects(:all).with(has_entry(:order => 'title'))
          GenericEntityMatcher.possible_matches(:title => 'The FOO Thing', :type => 'TestScrapedModel')
        end
        
        should "find all in alphabetical order of name if model has name attribute" do
          TestModelWithSpendingStat.expects(:all).with(has_entry(:order => 'name'))
          GenericEntityMatcher.possible_matches(:title => 'The FOO Thing', :type => 'TestModelWithSpendingStat')
        end
        
        context "return result which" do
          setup do
            @results = GenericEntityMatcher.possible_matches(:title => 'result 2', :type => 'TestModelWithSpendingStat')
          end

          should "be hash" do
            assert_kind_of Hash, @results
          end

          should "return array of MatchResult keyed to result" do
            assert_kind_of Array, result = @results[:result]
            assert_kind_of GenericEntityMatcher::MatchResult, result.first
            assert_equal @result_1.title, result.first.title
          end
          
          should "mark item as matching if titles match" do
            assert !@results[:result].first.match
            assert @results[:result].last.match
          end
          # 
          # should "be empty hash if no results" do
          #   assert_equal( {}, GenericEntityMatcher.possible_matches(:title => 'result 2', :type => 'TestScrapedModel'))
          # end
        end
        

     end


      # should "return empty string if empty string given" do
      #   assert_equal "", TitleNormaliser.normalise_title("")
      # end

    end

    context "The MatchResult class" do
      setup do
        @result = GenericEntityMatcher::MatchResult.new
      end

      should "have match accessor" do
        @result.instance_variable_set(:@match, 'foo')
        assert_equal 'foo', @result.match
      end
      
      should "have id accessor" do
        @result.instance_variable_set(:@id, 'foo')
        assert_equal 'foo', @result.id
      end
      
      should "have score accessor" do
        @result.instance_variable_set(:@score, 'foo')
        assert_equal 'foo', @result.score
      end
      
      should "have title accessor" do
        @result.instance_variable_set(:@title, 'foo')
        assert_equal 'foo', @result.title
      end
      
      should "have type accessor" do
        @result.instance_variable_set(:@type, 'foo')
        assert_equal 'foo', @result.type
      end
      
      should "have base_object accessor" do
        @result.instance_variable_set(:@base_object, 'foo')
        assert_equal 'foo', @result.base_object
      end
      
      context "when creating new from object" do
        setup do
          @base_obj = Factory(:generic_council)
          @result = GenericEntityMatcher::MatchResult.new(:base_object => @base_obj, :score => 42, :match => 'bar')
        end

        should "set id to be id of object" do
          assert_equal @base_obj.id, @result.id
        end

        should "set type to be class of object" do
          assert_equal 'Council', @result.type
        end

        should "set title to be name of object" do
          assert_equal @base_obj.title, @result.title
        end

        should "set extended_title instance variable to be extended_title of object if it has one" do
          @base_obj = Factory(:parish_council, :council => Factory(:generic_council))
          @result = GenericEntityMatcher::MatchResult.new(:base_object => @base_obj, :score => 42, :match => 'bar')
          assert_equal @base_obj.extended_title, @result.instance_variable_get(:@extended_title)
        end

        should "leave extended_title as nil if object doesn't have extended_title method" do
          assert_nil @result.instance_variable_get(:@extended_title)
        end

        should "store base object in base_object instance variable " do
          assert_equal @base_obj, @result.instance_variable_get(:@base_object)
        end
        
        should "store score in base_object instance variable " do
          assert_equal 42, @result.instance_variable_get(:@score)
        end
        
        should "store match in base_object instance variable " do
          assert_equal 'bar', @result.instance_variable_get(:@match)
        end
      end
      
      context "when returning extended_title" do
        setup do
          @result.instance_variable_set(:@title, 'Foo')
        end

        should "return extended_title instance_variable if set" do
          @result.instance_variable_set(:@extended_title, 'Foo Bar')
          assert_equal 'Foo Bar', @result.extended_title
        end

        should "return title if extended_title instance_variable not set" do
          assert_equal 'Foo', @result.extended_title
        end
      end
    end

  end
  
end
