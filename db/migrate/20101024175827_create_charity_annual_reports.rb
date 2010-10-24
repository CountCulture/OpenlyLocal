class CreateCharityAnnualReports < ActiveRecord::Migration
  def self.up
    create_table :charity_annual_reports do |t|
      t.integer :charity_id
      t.string  :annual_return_code
      t.date    :financial_year_start
      t.date    :financial_year_end
      t.integer :income_from_legacies
      t.integer :income_from_endowments
      t.integer :voluntary_income
      t.integer :activities_generating_funds
      t.integer :income_from_charitable_activities
      t.integer :investment_income
      t.integer :other_income
      t.integer :total_income
      t.integer :investment_gains
      t.integer :gains_from_asset_revaluations
      t.integer :gains_on_pension_fund
      t.integer :voluntary_income_costs
      t.integer :fundraising_trading_costs
      t.integer :investment_management_costs
      t.integer :grants_to_institutions
      t.integer :charitable_activities_costs
      t.integer :governance_costs
      t.integer :other_expenses
      t.integer :total_expenses
      t.integer :support_costs
      t.integer :depreciation
      t.integer :reserves
      t.integer :fixed_assets_at_start_of_year
      t.integer :fixed_assets_at_end_of_year
      t.integer :fixed_investment_assets_at_end_of_year
      t.integer :fixed_investment_assets_at_start_of_year
      t.integer :current_investment_assets
      t.integer :cash
      t.integer :total_current_assets
      t.integer :creditors_within_1_year
      t.integer :long_term_creditors_or_provisions
      t.integer :pension_assets
      t.integer :total_assets
      t.integer :endowment_funds
      t.integer :restricted_funds
      t.integer :unrestricted_funds
      t.integer :total_funds
      t.integer :employees
      t.integer :volunteers
      t.boolean :consolidated_accounts
      t.boolean :charity_only_accounts
      t.timestamps
    end
  end

  def self.down
    drop_table :charity_annual_reports
  end
end
