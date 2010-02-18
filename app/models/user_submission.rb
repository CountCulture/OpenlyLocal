class UserSubmission < ActiveRecord::Base
  belongs_to :council
  belongs_to :member
  validates_presence_of :council_id
  
  def twitter_account_name=(name)
    self[:twitter_account_name] = name.sub(/^@/, '')
  end
end
