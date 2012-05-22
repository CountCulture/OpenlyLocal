require File.expand_path('../../test_helper', __FILE__)

class AdminMailerTest < ActionMailer::TestCase
  
  context "when sending admin email" do
    setup do
      AdminMailer.deliver_admin_alert(:title => "Something has happened", :details => "An explanation of what has happened")
    end
    should "send email" do
      assert_sent_email  do |email|
        email.subject =~ /Something has happened/ && email.to.include?('countculture@gmail.com')
      end
    end
  end

end
