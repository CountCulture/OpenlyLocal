require File.expand_path('../../test_helper', __FILE__)

class ScraperRunnerTest < ActiveSupport::TestCase
  context "A ScraperRunner instance" do
    setup do
      @runner = ScraperRunner.new(:email_results => true, :limit => 42)
    end
    
    should "set email_results reader from options" do
      assert @runner.email_results
    end
    
    should "set email_results reader to false by default" do
      assert !ScraperRunner.new.email_results
    end
    
    should "set limit reader from options" do
      assert_equal 42, @runner.limit
    end
    
    should "set limit to 5 by default" do
      assert_equal 5, ScraperRunner.new.limit
    end
    
    should "have result_output accessor" do
      @runner.result_output = "foo"
      assert_equal "foo", @runner.result_output
    end
    
    should "set result_output to be empty string by default" do
      assert_equal "", ScraperRunner.new.result_output
    end
    
    context "when refreshing stale scrapers" do
      setup do
        ActionMailer::Base.deliveries.clear
        @scraper = Factory(:scraper)
        Scraper.stubs(:find).returns([@scraper])
      end
      
      should "find stale scrapers" do
        Scraper.expects(:find).returns([])
        @runner.refresh_stale
      end
      
      should "process stale scrapers" do
        @scraper.expects(:process).returns(@scraper)
        @runner.refresh_stale
      end
      
      should "summarize results in summary" do
        Scraper.expects(:find).returns([@scraper]*3)
        @scraper.stubs(:process).returns(stub(:results => stub_everything)).then.returns(stub(:results => stub_everything)).then.returns(stub(:results))
        @runner.refresh_stale
        assert_equal "3 scrapers processed, 1 problem(s)", @runner.instance_variable_get(:@summary)
      end

      context "when email_results is true" do
        setup do
          @runner.result_output = "some output"
          @runner.refresh_stale
        end

        should have_sent_email.with_subject(/Auto Scraping Report/).with_body(/some output/)
      end
      
      context "when sending email" do
        setup do
          @scraper.stubs(:process).returns(stub(:results => stub_everything))
          @runner.refresh_stale
        end

        should have_sent_email.with_subject(/1 scrapers processed/)
      end
      
      context "when email_results is not true" do
        setup do
          ScraperRunner.new.refresh_stale
        end

        should_not have_sent_email
      end
    end
    
  end
  
end
