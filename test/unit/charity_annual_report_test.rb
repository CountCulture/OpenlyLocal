require 'test_helper'

class CharityAnnualReportTest < ActiveSupport::TestCase
  
  context "the CharityAnnualReport class" do
    setup do
      @charity_annual_report = Factory(:charity_annual_report)
    end
    
    should have_db_column :charity_id
    should have_db_column :annual_return_code
    should have_db_column :financial_year_start
    should have_db_column :financial_year_end
    should have_db_column :income_from_legacies
    should have_db_column :income_from_endowments
    should have_db_column :voluntary_income
    should have_db_column :activities_generating_funds
    should have_db_column :income_from_charitable_activities
    should have_db_column :investment_income
    should have_db_column :other_income
    should have_db_column :total_income
    should have_db_column :investment_gains
    should have_db_column :gains_from_asset_revaluations
    should have_db_column :gains_on_pension_fund
    should have_db_column :voluntary_income_costs
    should have_db_column :fundraising_trading_costs
    should have_db_column :investment_management_costs
    should have_db_column :grants_to_institutions
    should have_db_column :charitable_activities_costs
    should have_db_column :governance_costs
    should have_db_column :other_expenses
    should have_db_column :total_expenses
    should have_db_column :support_costs
    should have_db_column :depreciation
    should have_db_column :reserves
    should have_db_column :fixed_assets_at_start_of_year
    should have_db_column :fixed_assets_at_end_of_year
    should have_db_column :fixed_investment_assets_at_end_of_year
    should have_db_column :fixed_investment_assets_at_start_of_year
    should have_db_column :current_investment_assets
    should have_db_column :cash
    should have_db_column :total_current_assets
    should have_db_column :creditors_within_1_year
    should have_db_column :long_term_creditors_or_provisions
    should have_db_column :pension_assets
    should have_db_column :total_assets
    should have_db_column :endowment_funds
    should have_db_column :restricted_funds
    should have_db_column :unrestricted_funds
    should have_db_column :total_funds
    should have_db_column :employees
    should have_db_column :volunteers
    should have_db_column :consolidated_accounts
    should have_db_column :charity_only_accounts
    
    should belong_to :charity
  end

end
