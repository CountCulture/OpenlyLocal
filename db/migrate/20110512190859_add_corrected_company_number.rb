class AddCorrectedCompanyNumber < ActiveRecord::Migration
  def self.up
    rename_column :charities, :normalised_company_number, :corrected_company_number
  end

  def self.down
    rename_column :charities, :corrected_company_number, :normalised_company_number
  end
end