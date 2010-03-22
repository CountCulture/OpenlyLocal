require 'test_helper'

class CouncilContactTest < ActiveSupport::TestCase
  subject { @council_contact }
  context "The CouncilContact class" do
    setup do
      @council_contact = Factory(:council_contact)
      @approved_contact = Factory(:council_contact, :council => Factory(:another_council), :name => 'Barney Rubble')
      @approved_contact.approve
    end
    
    should_belong_to :council 
    should_validate_presence_of :name
    should_validate_presence_of :position
    should_validate_presence_of :email
    should_validate_presence_of :council_id
    should_not_allow_mass_assignment_of :approved
    
    context 'when returning approved entries' do
      should 'only return approved contacts' do
        assert_equal [@approved_contact], CouncilContact.approved
      end
    end
    
    context 'when returning unapproved entries' do
      should 'only return unapproved contacts' do
        assert_equal [@council_contact], CouncilContact.unapproved
      end
    end
  end
  
  context 'An instance of the CouncilContact class' do
    setup do
      @council_contact = Factory(:council_contact)
    end
    
    context 'when approving council_contact' do
      should 'approve contact' do
        assert !@council_contact.approved?
        @council_contact.approve
        assert @council_contact.approved?
      end
    end
    
  end
end
