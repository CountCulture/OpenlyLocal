require File.expand_path('../../test_helper', __FILE__)

class InvestigationTest < ActiveSupport::TestCase
  def setup
    @investigation = Factory(:investigation)
  end

  context "The Investigation class" do
    
    should have_many :investigation_subject_connections
    should have_many(:member_subjects).through(:investigation_subject_connections)
    
    should validate_presence_of :standards_body

    [ :uid, :url, :related_organisation_name, :raw_html, :standards_body,
      :title, :subjects, :date_received, :date_completed, :description, :result,
      :case_details, :full_report_url,
    ].each do |column|
      should have_db_column column
    end
    
    should 'belong to related_organisation polymorphically' do
      organisation = Factory(:council)
      assert_equal organisation, Factory(:investigation, :related_organisation => organisation).related_organisation
    end
    
    should 'have many member_subjects by going through investigation_subject_connection association' do
      #shoulda test for this doesn't properly test polymorphicness of it
      subject = Factory(:member)
      investigation_subject_connection = InvestigationSubjectConnection.create!(:subject => subject, :investigation => @investigation)
      assert_equal 1, @investigation.member_subjects.size
      assert_equal subject, @investigation.member_subjects.first
    end
    
    context "before saving" do
      setup do
        @case_details = "some <font='Helvetica'>stylized text</font> with <a href='councillor22'>relative link</a> and an <a href='http://external.com/dummy'>absolute link</a>."*10
        @investigation.case_details = @case_details
      end
      
      context "and description is blank" do

        should "calculate precis from case_details as description" do
          DocumentUtilities.expects(:precis).with(@case_details)
          @investigation.save!
        end
        
        should "save calculated precis as description" do
          DocumentUtilities.stubs(:precis).with(@case_details).returns('foo bar')
          @investigation.save!
          assert_equal 'foo bar', @investigation.description
        end
      end
      
      context "and description exists" do
        setup do
          @investigation.description = 'some words'
        end

        should "not calculate precis" do
          DocumentUtilities.expects(:precis).never
          @investigation.save!
        end
        
        should "not change description" do
          @investigation.save!
          assert_equal 'some words', @investigation.description
        end
      end
    end
  end
  
  context "An instance of the Investigation class" do

    context "when returning standards_body_name" do

      should "return body associated with acronym" do
        assert_equal "Standards Body for England", @investigation.standards_body_name
      end
    end
    
    context "when returning title" do
      setup do
        @investigation.attributes = {:standards_body => 'SBE', :title => 'AB123', :related_organisation_name => 'Some Council'}
      end

      should "include full name of standards_body" do
        assert_match /Standards Body for England/, @investigation.title
      end

      # should "include organisation_name" do
      #   assert_match /Some Council/, @investigation.title
      # end
      # 
      should "include title value" do
        assert_match /AB123/, @investigation.title
      end
    end

  end
end
