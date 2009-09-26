class Membership < ActiveRecord::Base
  belongs_to :member
  belongs_to :committee
  # belongs_to :council
  validates_presence_of :member_id
  validates_presence_of :committee_id
end
