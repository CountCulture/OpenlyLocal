class UserSubmission < ActiveRecord::Base
  belongs_to :council
  belongs_to :member
  validates_presence_of :council_id
  attr_protected :approved
  named_scope :unapproved, :conditions => {:approved => false}
  
  # Note: approving a user_submission, means we update member with info (and
  # mark as approved)
  def approve
    errors.add(:member_id, "can't be found. Can't approve") and return unless self.member
    update_attribute(:approved, true)
    member.update_from_user_submission(self)
    Delayed::Job.enqueue(Tweeter.new("@#{twitter_account_name} has been added to @OpenlyLocal #ukcouncillors list ", {:url => "http://twitter.com/OpenlyLocal/ukcouncillors"})) if twitter_account_name?
  end

  def validate
    errors.add_to_base("Member info is missing") if member_name.blank? && member_id.blank?
  end
  
  def twitter_account_name=(name)
    self[:twitter_account_name] = name.sub(/^@/, '')
  end
  
end
