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
    errors.add_to_base("Missing required info") unless submission_details && submission_details.valid?
  end
  
  # Get submission_details object to run approve method, and then update approved flag with result
  def approve
    res = submission_details.approve(self)
    update_attribute(:approved, res)
    res
  end

  # @note Overrides default method created by ActiveRecord.
  def submission_details=(attribs)
    self[:submission_details] = if attribs && @submission_type
      class_name = @submission_type.camelize
      if Object.const_defined? class_name
        class_name.constantize.new(attribs)
      else
        attribs
      end
    else
      attribs
    end
  end

  def submission_type
    @submission_type ||= self[:submission_details] && self[:submission_details].class.to_s.underscore
  end
  
  # Expects the params hash, which is used to initialize the user submission, to
  # have a "submission_type" key.
  def submission_type=(sub_type)
    @submission_type = sub_type
    class_name = @submission_type.camelize
    if Object.const_defined? class_name
      if self[:submission_details].is_a? Hash
        self[:submission_details] = class_name.constantize.new(self[:submission_details])
      elsif !self[:submission_details]
        self[:submission_details] = class_name.constantize.new
      end
    end
  end
  
  def title
    "#{submission_type.humanize} for #{item.title}"
  end
  
  def twitter_account_name=(name)
    self[:twitter_account_name] = name.sub(/^@/, '')
  end
  
end
