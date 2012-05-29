require File.expand_path('../../test_helper', __FILE__)

class ClassificationTest < ActiveSupport::TestCase
  context "The Classification class" do
    setup do
      @classification = Factory(:classification)
    end

    should validate_presence_of :title
    should validate_presence_of :grouping
    # should validate_uniqueness_of(:uid).scoped_to :area_type
    should have_db_column :grouping
    should have_db_column :extended_title
    should have_db_column :parent_id
    
    should "have many child classifications" do
      child = Factory(:classification, :parent_id => @classification.id)
      assert_equal [child], @classification.children
    end

    should "belong to parent classification" do
      child = Factory(:classification, :parent_id => @classification.id)
      assert_equal @classification, child.parent
    end
  end

  context "A Classification instance" do
    setup do
      @classification = Factory(:classification)
    end
    
    context "when returning grouping_title" do

      should "return full title for grouping" do
        assert_equal Classification::GROUPINGS[@classification.grouping].first, @classification.grouping_title
      end

      should "return nil if no matching grouping" do
        @classification.grouping = 'foo'
        assert_nil @classification.grouping_title
      end
    end
    
    context "when returning grouping_url" do
      should "return url for grouping" do
        assert_equal Classification::GROUPINGS[@classification.grouping].last, @classification.grouping_url
      end

      should "return nil if no matching grouping" do
        @classification.grouping = 'foo'
        assert_nil @classification.grouping_url
      end
    end
    
    context "when returning extended title" do
      
      should "return extended title with grouping title" do
        @classification.extended_title = 'Foo Bar'
        assert_equal "Foo Bar (#{@classification.grouping_title})", @classification.extended_title
      end
      
      should "return title with grouping title if extended_title blank" do
        assert_equal "#{@classification.title} (#{@classification.grouping_title})", @classification.extended_title
      end
    end
  end
end
