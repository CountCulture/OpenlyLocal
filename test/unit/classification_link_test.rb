require File.expand_path('../../test_helper', __FILE__)

class ClassificationLinkTest < ActiveSupport::TestCase

  context "The ClassificationLink class" do
    setup do
      @classification_link = Factory(:classification_link)
    end

    should validate_presence_of :classification_id
    should validate_presence_of :classified_type
    should validate_presence_of :classified_id

    should belong_to :classification
    
    should 'belong to classified polymorphically' do
      classified = Factory(:charity)
      assert_equal classified, Factory(:classification_link, :classified => classified).classified
    end

    should have_db_column :classification_id
    should have_db_column :classified_type
    should have_db_column :classified_id
  end
  
  # context 'an instance of the ClassificationLink class' do
  #   
  # 
  # end
end
