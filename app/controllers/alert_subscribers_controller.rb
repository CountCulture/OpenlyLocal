class AlertSubscribersController < ApplicationController
  
  def new
    @title = "Subscribe to planning application alerts"
    @alert_subscriber = AlertSubscriber.new
  end
  
  def confirm
    @confirmed = AlertSubscriber.confirm_from_email_and_code(params[:email], params[:confirmation_code])
    render :template => 'alert_subscribers/confirmed'
  end
  
  def create
    @alert_subscriber = AlertSubscriber.new(params[:alert_subscriber])
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
