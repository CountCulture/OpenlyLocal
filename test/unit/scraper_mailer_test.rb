require 'test_helper'

class ScraperMailerTest < ActionMailer::TestCase
  context "A ScraperMailer auto_scraping_report email" do
    setup do
      @report_text = "auto_scraping_report body text"
      @report = ScraperMailer.create_auto_scraping_report(:report => @report_text, :summary => "3 successes")
    end

    should "be sent from countculture" do
      assert_equal "countculture@googlemail.com", @report.from[0]
    end
    
    should "be sent to countculture" do
      assert_equal "countculture@googlemail.com", @report.to[0]
    end
    
    should "include summary in subject" do
      assert_match /3 successes/, @report.subject
    end
    
    should "include report text in body" do
      assert_match /#{@report_text}/, @report.body
    end
  end
  
  context "A ScraperMailer scraping_report email" do
    setup do
      @scraper = Factory(:scraper)
      @scraper.stubs(:results => [ ScrapedObjectResult.new(Member.new(:first_name => "Fred", :last_name => "Flintstone")) ])
      @scraper.errors.add_to_base("There is a foo problem")
      @report = ScraperMailer.create_scraping_report(@scraper)
    end

    should "be sent from countculture" do
      assert_equal "countculture@googlemail.com", @report.from[0]
    end
    
    should "be sent to countculture" do
      assert_equal "countculture@googlemail.com", @report.to[0]
    end
    
    should "include scraper info in subject" do
      assert_match /#{@scraper.title}/, @report.subject
    end
    
    should "send as html email" do
      assert_equal "text/html", @report.content_type
      assert_match /<html>/, @report.body
    end
    
    should "list scraped object in body" do
      assert_match /<div.+class=\".+new member/, @report.body
    end
    
    should "list changed attributes in body" do
      assert_match /#{@report_text}/, @report.body
    end
    
    should "list errors in body" do
      assert_match /div class="error.+There is a foo problem/, @report.body
    end
  end
end
