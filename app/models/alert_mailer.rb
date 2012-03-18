class AlertMailer < ActionMailer::Base

  def planning_alert(params={})
    @recipients   = params[:subscriber].email
    @from         = 'alerts@openlylocal.com'
    @subject      = "OpenlyLocal Alert :: New Planning Application: #{params[:planning_application].address}"
    @sent_on      = Time.now
    @body[:planning_application] = params[:planning_application]
    @headers      = {}
  end
  
end
