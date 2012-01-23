class ParishCouncil < ActiveRecord::Base
  belongs_to :council
  include TitleNormaliser::Base
  include SpendingStatUtilities::Base
  include SpendingStatUtilities::Payee
  include SocialNetworkingUtilities::Base
  
  validates_presence_of :title, :os_id
  alias_attribute :url, :website

  # overload #normalise_title included from mixin module so 'Town Council', 'Parish Council' etc are removed
  def self.normalise_title(raw_title)
    semi_normed_title = raw_title.squish.gsub(/Parish Council|Town Council|Council/mi, '')
    TitleNormaliser.normalise_title(semi_normed_title)
  end
  
  def self.reconcile(params={})
    return if params[:q].blank?
    possible_parishes = find_all_by_normalised_title(normalise_title(params[:q]))
    possible_parishes = possible_parishes.select{ |p| (params[:parent_council] == p.council) || (params[:parent_council] == p.council.try(:parent_authority)) } if params[:parent_council]
    possible_parishes
  end
  
  def extended_title
    council ? "#{title} (#{council.title})" : title
  end
  
  def openlylocal_url
    "http://#{DefaultDomain}/parish_councils/#{to_param}"
  end
  
  def resource_uri
    "http://#{DefaultDomain}/id/parish_councils/#{id}"
  end

  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
end
