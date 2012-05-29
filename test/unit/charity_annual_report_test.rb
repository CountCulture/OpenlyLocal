require File.expand_path('../../test_helper', __FILE__)

class CharityAnnualReportTest < ActiveSupport::TestCase
  
  context "the CharityAnnualReport class" do
    setup do
      @charity_annual_report = Factory(:charity_annual_report)
    end
    
    [ :charity_id, :annual_return_code, :financial_year_start,
      :financial_year_end, :income_from_legacies, :income_from_endowments,
      :voluntary_income, :activities_generating_funds,
      :income_from_charitable_activities, :investment_income, :other_income,
      :total_income, :investment_gains, :gains_from_asset_revaluations,
      :gains_on_pension_fund, :voluntary_income_costs,
      :fundraising_trading_costs, :investment_management_costs,
      :grants_to_institutions, :charitable_activities_costs,
      :governance_costs, :other_expenses, :total_expenses, :support_costs,
      :depreciation, :reserves, :fixed_assets_at_start_of_year,
      :fixed_assets_at_end_of_year, :fixed_investment_assets_at_end_of_year,
      :fixed_investment_assets_at_start_of_year, :current_investment_assets,
      :cash, :total_current_assets, :creditors_within_1_year,
      :long_term_creditors_or_provisions, :pension_assets, :total_assets,
      :endowment_funds, :restricted_funds, :unrestricted_funds, :total_funds,
      :employees, :volunteers, :consolidated_accounts, :charity_only_accounts,
    ].each do |column|
      should have_db_column column
    end
    should belong_to :charity
  end

end
