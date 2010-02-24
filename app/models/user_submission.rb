class UserSubmission < ActiveRecord::Base
  belongs_to :council
  belongs_to :member
  validates_presence_of :council_id
  attr_protected :approved
  before_validation :before_approval_action
  
  # Note: approving a user_submission, means we update member with info (which
  # in turn deletes submission)
  def approve=(bool)
    return unless bool
    errors.add(:member_id, "can't be found. Can't approve") and return unless self.member
    member.update_from_user_submission(self) 
  end

  def validate
    errors.add_to_base("Member info is missing") if member_name.blank? && member_id.blank?
  end
  
  def twitter_account_name=(name)
    self[:twitter_account_name] = name.sub(/^@/, '')
  end
  
  private
  def before_approval_action
    if approved && !approved_was
      errors.add(:base, "Member can't be found. Can't approve") and return false unless member
      member.update_from_user_submission(self)
    end
    true
  end
end
