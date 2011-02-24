require 'test_helper'

class TestNormalisedModel <ActiveRecord::Base
  set_table_name "entities"
  include TitleNormaliser::Base
end


class TitleNormaliserTest < Test::Unit::TestCase
  
  context "The TitleNormaliser module" do
    
    context "when normalising title" do

      should "return nil if nil given" do
        assert_nil TitleNormaliser.normalise_title(nil)
      end

      should "return empty string if empty string given" do
        assert_equal "", TitleNormaliser.normalise_title("")
      end

      should "normalise title" do
        OriginalTitleAndNormalisedTitle = {
          "The Super  Important Thing" => "super important thing",
          "The Super (Important) Thing" => "super important thing",
          " Less-Important thing" => "less important thing",
          "multi\nline \t thing" => "multi line thing",
          "Ways and Means" => "ways and means",
          " Ways and Means   " => "ways and means",
          "Ways & Means" => "ways and means",
          "Ways&Means" => "ways and means",
          "Important: another thing" => "important another thing",
          "Children's thing" => "childrens thing",
          "St. something" => "st something",
          "The 'Theatre' thing" => "theatre thing",
          'The "Theatre" thing' => "theatre thing",
          "The Theatre thing" => "theatre thing"
        }

        OriginalTitleAndNormalisedTitle.each do |orig_title, normalised_title|
          assert_equal( normalised_title, TitleNormaliser.normalise_title(orig_title), "failed for #{orig_title}")
        end
      end
    end

    context "when normalising company_title" do
      
      should "return nil if nil given" do
        assert_nil TitleNormaliser.normalise_company_title(nil)
      end

      should "return empty string if empty string given" do
        assert_equal "", TitleNormaliser.normalise_company_title("")
      end

      should "normalise title" do
        OriginalTitleAndNormalisedCompanyTitle = {
          "Foo Bar & Baz" => "foo bar and baz",
          "Foo Bar & Baz Ltd" => "foo bar and baz limited",
          "Foo Bar & Baz Ltd." => "foo bar and baz limited",
          "Foo Bar & Baz PLC" => "foo bar and baz plc",
          "Foo Bar & Baz Public Limited Company" => "foo bar and baz plc",
          "Foo Bar & Baz (South) Limited" => "foo bar and baz south limited",
          "Foo Bar & Baz (South & NORTH) Limited" => "foo bar and baz south and north limited",
          "Foo Bar & Baz Ltd t/a bar foo" => "foo bar and baz limited",
          "Foo Bar & Baz Ltd T/A bar foo" => "foo bar and baz limited"
        }

        OriginalTitleAndNormalisedCompanyTitle.each do |orig_title, normalised_title|
          assert_equal( normalised_title, TitleNormaliser.normalise_company_title(orig_title), "failed for #{orig_title}")
        end
      end
    end


    context "when normalising financial_sum" do
      
      should "return nil if nil given" do
        assert_nil TitleNormaliser.normalise_financial_sum(nil)
      end

      should "return empty string if empty string given" do
        assert_equal "", TitleNormaliser.normalise_financial_sum("")
      end

      should "normalise financial_sum" do
        OriginalTitleAndNormalisedFinancialSum = {
          "32.43" => "32.43",
          "3243" => "3243",
          "12,345.60" => "12345.60",
          12345.60 => 12345.60,
          "12,345.654" => "12345.654",
          "12,345,678.6" => "12345678.6",
          "£12,345,678.6" => "12345678.6",
          "\24312,345.6" => "12345.6",
          "£12, 345 ,678.6" => "12345678.6",
          "(12,345.60)" => "-12345.60",
          "(£12,345.60)" => "-12345.60",
          "-£12,345.60" => "-12345.60"
        }

        OriginalTitleAndNormalisedFinancialSum.each do |orig_sum, normalised_sum|
          assert_equal( normalised_sum, TitleNormaliser.normalise_financial_sum(orig_sum), "failed for #{orig_sum}")
        end
      end
    end

    context "when normalising url" do
      should "return nil if nil given" do
        assert_nil TitleNormaliser.normalise_url(nil)
      end

      should "return nil if empty string given" do
        assert_nil TitleNormaliser.normalise_url("")
      end

      should "normalise url" do
        OriginalTitleAndNormalisedUrl = {
          "http://www.foo.com" => "http://www.foo.com",
          "www.foo.com" => "http://www.foo.com",
          "https://www.foo.com" => "https://www.foo.com",
          "http://http://www.foo.com" => "http://www.foo.com",
          "//http://pages.lvillage.com/chalgrove/" => "http://pages.lvillage.com/chalgrove/",
          "www.http://users.aol.com/snewsyn" => "http://users.aol.com/snewsyn"
        }

        OriginalTitleAndNormalisedUrl.each do |orig_url, normalised_url|
          assert_equal( normalised_url, TitleNormaliser.normalise_url(orig_url), "failed for #{orig_url}")
        end
      end
    end
  end
  
  context "A class which mixes in the TitleNormaliser::Base module" do
    setup do
      
    end

    should 'have normalise_title class method' do
      assert TestNormalisedModel.respond_to?(:normalise_title)
    end
    
    context "and when normalising title" do
      should "normalise title using TitleNormaliser" do
        TitleNormaliser.expects(:normalise_title).with('foo bar')
        TestNormalisedModel.normalise_title('foo bar')
      end
    end  
  end
  
  context "An instance of a class which mixes in the TitleNormaliser::Base module" do
    setup do
      @test_normalised_model = TestNormalisedModel.new
    end

    context "when saving" do
      should "normalise title" do
        @test_normalised_model.expects(:normalise_title)
        @test_normalised_model.save!
      end
  
      should "save normalised title" do
        @test_normalised_model.title = "Foo & Baz Dept"
        @test_normalised_model.save!
        assert_equal "foo and baz dept", @test_normalised_model.reload.normalised_title
      end
    end

  end
end
