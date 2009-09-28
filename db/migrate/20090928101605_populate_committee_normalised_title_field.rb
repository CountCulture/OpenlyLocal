class PopulateCommitteeNormalisedTitleField < ActiveRecord::Migration
  def self.up
    Committee.find_in_batches do |group|
      group.each(&:save)
    end
  end

  def self.down
    Committee.update_all(:normalised_title => nil)
  end
end
