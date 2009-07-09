class Ward < ActiveRecord::Base
  belongs_to :council
  has_many :members
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :council_id
  alias_attribute :title, :name

end
