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
    
    should "alias name as title" do
      assert_equal @poltical_party.name, @poltical_party.title
    end

    context "when normalising title" do
      setup do
        @original_title_and_normalised_title = {
          "The Conservative Party" => "conservative",
          "Conservative Party [The]" => "conservative",
          "Motorists, Equity&Unity Party" => "motorists equity and unity",
          "Motorists, Equity & Unity Party" => "motorists equity and unity",
          "Northampton - Save Our Public Services" => "northampton save our public services"
        }
      end
      
      should "normalise title" do
        @original_title_and_normalised_title.each do |orig_title, normalised_title|
          assert_equal( normalised_title, PoliticalParty.normalise_title(orig_title), "failed for #{orig_title}")
        end
      end
      
    end
  end

  context "A PoliticalParty instance" do
    setup do
      @political_party = Factory(:political_party)
    end
    
    should "return electoral_commission_url based on electoral_commission id" do
      assert_equal "http://registers.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmPartyID=#{@political_party.electoral_commission_uid}&frmType=partydetail", @political_party.electoral_commission_url
    end
    
    context "when returning normalised_title" do
      
      should "return normalised version of title" do
        PoliticalParty.expects(:normalise_title).with(@political_party.name).returns("bar")
        assert_equal "bar", @political_party.normalised_title
      end
    end
    
    context "when returning whether name is matched" do
      should "return false by default" do
        assert !@political_party.matches_name?
        assert !@political_party.matches_name?(nil)
      end
      
      should "return false by when no match" do
        assert !@political_party.matches_name?("foobar")
      end
      
      should "return true when supplied string equals name" do
        assert @political_party.matches_name?(@political_party.name)
      end
      
      should "return true when supplied string equals normalised_title" do
        assert @political_party.matches_name?(@political_party.normalised_title)
      end
      
      should "return true when supplied string equals an alternative name" do
        @political_party.update_attribute(:alternative_names, ["Something Else", "Another Thing"])
        assert @political_party.reload.matches_name?("Something Else")
      end
      
    end
  end
end
