class ParishCouncil < ActiveRecord::Base
  belongs_to :council
  include TitleNormaliser::Base
  include SpendingStatUtilities::Base
  include SpendingStatUtilities::Payee
  
  validates_presence_of :title, :os_id

  # overload #normalise_title included from mixin module so 'Town Council', 'Parish Council' etc are removed
  def self.normalise_title(raw_title)
    semi_normed_title = raw_title.squish.gsub(/Parish Council|Town Council|Council/mi, '')
    TitleNormaliser.normalise_title(semi_normed_title)
  end

end
