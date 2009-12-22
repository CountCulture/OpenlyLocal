class AdminMailer < ActionMailer::Base

  def admin_alert(alert)
    @recipients   = 'countculture@gmail.com' 
    @from         = 'countculture@gmail.com'
    @subject      = "OpenlyLocal Admin message :: " + alert[:title]
    @sent_on      = Time.now
    @body[:alert] = alert
    @headers      = {}
  end
  
end
