class AlertSubscribersController < ApplicationController
  
  def new
    @title = "OpenlyLocal Planning Alerts"
    @alert_subscriber = AlertSubscriber.new(:email => params[:email], :postcode_text => params[:postcode], :distance => params[:distance])
  end
  
  def confirm
    @subscriber = AlertSubscriber.confirm_from_email_and_code(params[:email], params[:confirmation_code])
    if @subscriber
      flash[:notice] = "Your OpenlyLocal Planning Alerts subscription is active! You will now receive alerts for planning applications within #{(@subscriber.distance * 1000).to_i} of #{@subscriber.postcode.code}."
      redirect_to :controller => 'areas', :action => 'search', :postcode => @subscriber.postcode.code
    else
      render :template => 'alert_subscribers/confirmed'
    end
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
