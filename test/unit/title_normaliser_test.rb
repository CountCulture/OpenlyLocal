require 'test_helper'

class TitleNormaliserTest < Test::Unit::TestCase
  OriginalTitleAndNormalisedTitle = {
    "Super  Important Committee" => "super important",
    "Super  Important Cttee" => "super important",
    " Less Important Sub-Committee" => "less important sub",
    "multi\nline \t committee" => "multi line",
    "Ways and Means committee" => "ways and means",
    "The Ways and Means committee" => "ways and means",
    "Ways & Means committee" => "ways and means",
    "Ways&Means committee" => "ways and means",
    "The Theatre committee" => "theatre"
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
