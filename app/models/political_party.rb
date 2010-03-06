class PoliticalParty < ActiveRecord::Base
  validates_presence_of :name, :electoral_commission_uid
  serialize :alternative_names
  
  def electoral_commission_url
    "http://registers.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmPartyID=#{electoral_commission_uid}&frmType=partydetail"
  end
end
