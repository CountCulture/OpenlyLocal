require 'test_helper'

class InvestigationSubjectConnectionTest < ActiveSupport::TestCase
  def setup
    @investigation = Factory(:investigation_subject_connection)
  end

  context "The InvestigationSubjectConnection class" do
    
    should have_db_column :investigation_id
    should have_db_column :subject_id
    should have_db_column :subject_type
    
    should belong_to :investigation
    
    should 'belong to subject polymorphically' do
      subject = Factory(:member)
      assert_equal subject, Factory(:investigation_subject_connection, :subject => subject).subject
    end
    
    should validate_presence_of :subject_id
    should validate_presence_of :subject_type
    should validate_presence_of :investigation_id
  end
end
