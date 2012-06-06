class AlertSubscribersController < ApplicationController
  
  def new
    @title = "OpenlyLocal Planning Alerts"
    @alert_subscriber = AlertSubscriber.new(:email => params[:email], :postcode_text => params[:postcode], :distance => params[:distance])
  end
  
  def confirm
    @confirmed = AlertSubscriber.confirm_from_email_and_code(params[:email], params[:confirmation_code])
    render :template => 'alert_subscribers/confirmed'
  end
  
  def create
    @alert_subscriber = AlertSubscriber.new({'distance' => 0.2}.merge(params[:alert_subscriber]))
    if @alert_subscriber.save
      render :template => 'alert_subscribers/subscribed'
    else
      render :action => "new"
    end
  end
  
  def unsubscribe
    @unsubscribed = AlertSubscriber.unsubscribe_user_from_email_and_token(params[:email], params[:token])
  end
end
