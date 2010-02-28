require 'test_helper'

class TitleNormaliserTest < Test::Unit::TestCase
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
  
  context "The TitleNormaliser module" do

    should "return nil if nil given" do
      assert_nil TitleNormaliser.normalise_title(nil)
    end

    should "return empty string: if empty string given" do
      assert_equal "", TitleNormaliser.normalise_title("")
    end

    should "normalise title" do
      OriginalTitleAndNormalisedTitle.each do |orig_title, normalised_title|
        assert_equal( normalised_title, TitleNormaliser.normalise_title(orig_title), "failed for #{orig_title}")
      end
    end

  end
  
end
