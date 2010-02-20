class UserSubmission < ActiveRecord::Base
  belongs_to :council
  belongs_to :member
  validates_presence_of :council_id
  
  def validate
    errors.add_to_base("Member info is missing") if member_name.blank? && member_id.blank?
  end
  
  def twitter_account_name=(name)
    self[:twitter_account_name] = name.sub(/^@/, '')
  end
end
