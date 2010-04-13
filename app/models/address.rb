class Address < ActiveRecord::Base
  belongs_to :addressee, :polymorphic => true
  validates_presence_of :addressee_type, :addressee_id
end
