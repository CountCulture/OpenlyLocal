class Boundary < ActiveRecord::Base
  belongs_to :area, :polymorphic => true
end
