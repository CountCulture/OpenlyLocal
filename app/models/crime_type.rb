class CrimeType < ActiveRecord::Base
  validates_presence_of :name, :uid
end
