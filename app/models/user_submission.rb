class UserSubmission < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  belongs_to :member
  validates_presence_of :item_id, :item_type, :submission_details
  attr_protected :approved
  named_scope :unapproved, :conditions => {:approved => false}
  serialize :submission_details
  attr_writer :submission_type
  
  # Note: approving a user_submission, means we update member with info (and
  # mark as approved)
  # def approve
  #   errors.add(:member_id, "can't be found. Can't approve") and return unless self.member
  #   update_attribute(:approved, true)
  #   member.update_from_user_submission(self)
  #   Delayed::Job.enqueue(Tweeter.new("@#{twitter_account_name} has been added to @OpenlyLocal #ukcouncillors list ", {:url => "http://twitter.com/OpenlyLocal/ukcouncillors"})) if twitter_account_name?
  # end

  def validate
    # errors.add_to_base("Member info is missing") if member_name.blank? && member_id.blank?
    errors.add_to_base("Missing required info") unless submission_details&&submission_details.valid?
  end
  
  # Get submission_details object to run approve method, and then update approved flag with result
  def approve
    puts "**** about to run UserSubmission#approve on #{self.inspect}"
    puts "**** result of approval on  #{submission_details.inspect} = #{submission_details.approve(self)}"
    update_attribute(:approved, submission_details.approve(self))
  end
  
  def submission_details=(attribs)
    self[:submission_details] = attribs.nil? ? nil : (@submission_type ? @submission_type.camelize.constantize.new(attribs) : attribs )
  end
  
  def submission_type
    @submission_type ||= self[:submission_details]&&self[:submission_details].class.to_s.underscore
  end
  
  def submission_type=(sub_type)
    @submission_type = sub_type
    self[:submission_details] = 
              (self[:submission_details].is_a?(Hash) ? 
                  @submission_type.camelize.constantize.new(self[:submission_details]) : 
                  (self[:submission_details]||@submission_type.camelize.constantize.new) )
  end
  
  def title
    "#{submission_type.humanize} for #{item.title}"
  end
  
  def twitter_account_name=(name)
    self[:twitter_account_name] = name.sub(/^@/, '')
  end
  
end
