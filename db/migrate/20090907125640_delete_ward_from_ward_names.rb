class DeleteWardFromWardNames < ActiveRecord::Migration
  def self.up
    wards = Ward.all(:conditions => "name LIKE '% Ward$'").each do |w|
      w.update_attribute(:name, w.name) # pass through name accessor which strinps off 'Ward'
    end
  end

  def self.down
  end
end
