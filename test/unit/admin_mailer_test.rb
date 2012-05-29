require File.expand_path('../../test_helper', __FILE__)

class AdminMailerTest < ActionMailer::TestCase
  
  context "when sending admin email" do
    setup do
      AdminMailer.deliver_admin_alert(:title => "Something has happened", :details => "An explanation of what has happened")
    end

    should have_sent_email.with_subject(/Something has happened/).to('countculture@gmail.com')
  end

end
