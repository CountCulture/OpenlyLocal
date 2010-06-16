require 'test_helper'

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
          " Less-Important thing" => "less important thing",
          "multi\nline \t thing" => "multi line thing",
          "Ways and Means" => "ways and means",
          "Ways & Means" => "ways and means",
          "Ways&Means" => "ways and means",
          "Important: another thing" => "important another thing",
          "Children's thing" => "childrens thing",
          "St. something" => "st something",
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
          "Foo Bar & Baz (South) Limited" => "foo bar and baz (south) limited",
          "Foo Bar & Baz (South & NORTH) Limited" => "foo bar and baz (south and north) limited",
          "Foo Bar & Baz Ltd t/a bar foo" => "foo bar and baz limited",
          "Foo Bar & Baz Ltd T/A bar foo" => "foo bar and baz limited"
        }

        OriginalTitleAndNormalisedCompanyTitle.each do |orig_title, normalised_title|
          assert_equal( normalised_title, TitleNormaliser.normalise_company_title(orig_title), "failed for #{orig_title}")
        end
      end
    end


  end
  
end
