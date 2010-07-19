class AddSpendingStatToCouncils < ActiveRecord::Migration
  def self.up
    Council.all.each { |c| c.create_spending_stat }
    Council.all(:joins => :suppliers, :group => "councils.id").each{|c| c.spending_stat.perform}
  end

  def self.down
    Council.all.each { |c| c.spending_stat.destroy }
  end
end
