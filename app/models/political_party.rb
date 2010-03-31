class PoliticalParty < ActiveRecord::Base
  validates_presence_of :name, :electoral_commission_uid
  serialize :alternative_names
  alias_attribute :title, :name
  
  def self.find_from_resource_uri(resource_uri)
    case resource_uri
    when /openelectiondata.org\/id\/parties\/(\d+)/i
      find_by_electoral_commission_uid($1)
    end
  end
  
  def self.normalise_title(raw_title)
    semi_normed_title = raw_title.gsub(/\[.+\]|party|,/i,'')
    TitleNormaliser.normalise_title(semi_normed_title)
  end
  
  def electoral_commission_url
    "http://registers.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmPartyID=#{electoral_commission_uid}&frmType=partydetail"
  end
  
  def normalised_title
    self.class.normalise_title(name)
  end
  
  def matches_name?(poss_name=nil)
    return false if poss_name.blank?
    (self.class.normalise_title(poss_name) == normalised_title) || (alternative_names && alternative_names.include?(poss_name))
  end
end
