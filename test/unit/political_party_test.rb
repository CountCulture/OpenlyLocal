require 'test_helper'

class PoliticalPartyTest < ActiveSupport::TestCase
  subject { @poltical_party }

  context "The PoliticalParty class" do
    setup do
      @poltical_party = Factory(:political_party)
    end

    should_validate_presence_of :name
    should_validate_presence_of :electoral_commission_uid
    
    should_have_db_columns :alternative_names, :wikipedia_name, :colour, :url

    should "serialize alternative_names" do
      party = Factory(:political_party, :alternative_names => ["foo", "bar"])
      assert_equal ["foo", "bar"], party.reload.alternative_names
    end
  end

  context "A PoliticalParty instance" do
    setup do
      @political_party = Factory(:political_party)
    end
    
    should "return electoral_commission_url based on electoral_commission id" do
      assert_equal "http://registers.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmPartyID=#{@political_party.electoral_commission_uid}&frmType=partydetail", @political_party.electoral_commission_url
    end
  end
end
