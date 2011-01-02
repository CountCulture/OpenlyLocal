class AdminController < ApplicationController
  before_filter :authenticate

  def index
    @title = 'Admin'
    @hyperlocal_sites = HyperlocalSite.find_all_by_approved(false)
    @user_submissions = UserSubmission.unapproved(:include=>:item)
    @unapproved_contacts = CouncilContact.unapproved
    @delayed_job_count = Delayed::Job.connection.execute("show table status like 'delayed_jobs'").fetch_hash["Rows"]
    @unimported_spending_data_councils = Service.spending_data_services_for_councils
    @senior_staff_data_councils = Service.for_lgsl_id(LdgService::SENIOR_STAFF_LGSL)
    @contract_data_councils = Service.for_lgsl_id(LdgService::CONTRACT_DATA_LGSL)
  end

end
