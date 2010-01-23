class PensionFund < ActiveRecord::Base
  has_many :councils
  validates_presence_of :name
  validates_uniqueness_of :name
  alias_attribute :title, :name
  default_scope :order => 'name'

  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
end
