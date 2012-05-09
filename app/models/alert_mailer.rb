class AlertMailer < ActionMailer::Base
  config_file = "#{RAILS_ROOT}/config/smtp_gmail.yml"
  config_options = YAML.load_file(config_file)
  config_options['alerts'].symbolize_keys.each do |k,v|
    @@smtp_settings[k] = v
  end
  # self.override_smtp_settings

  def confirmation(subscriber)
    @recipients   = subscriber.email
    @from         = 'alerts@openlylocal.com'
    @subject      = "OpenlyLocal Alert :: Please confirm your Planning Application subscription"
    @sent_on      = Time.now
    @body[:subscriber] = subscriber
    @headers      = {}
  end
  
  def planning_alert(params={})
    @recipients   = params[:subscriber].email
    @from         = 'alerts@openlylocal.com'
    @subject      = "OpenlyLocal Alert :: New Planning Application: #{params[:planning_application].address}"
    @sent_on      = Time.now
    @body[:planning_application] = params[:planning_application]
    @body[:subscriber] = params[:subscriber]
    @headers      = {}
  end
  
  private
  def self.override_smtp_settings
    config_file = "#{RAILS_ROOT}/config/smtp_gmail.yml"
    config_options = YAML.load_file(config_file)
    config_options['alerts'].symbolize_keys.each do |k,v|
      @@smtp_settings[k] = v
    end
  end
  
end
