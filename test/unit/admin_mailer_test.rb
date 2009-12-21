require 'test_helper'

class AdminMailerTest < ActionMailer::TestCase
  
  context "when sending admin email" do
    setup do
      AdminMailer.deliver_admin_alert(:title => "Something has happened", :details => "An explanation of what has happened")
    end
    should "send email" do
      assert_sent_email  do |email|
        email.subject =~ /Something has happened/ && email.to.include?('countculture@email.com')
      end
    end
  end

end
