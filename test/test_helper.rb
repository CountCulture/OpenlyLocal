ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'test_models/test_models'
require 'factory_girl'
Dir.glob(File.dirname(__FILE__) + "/factories/*").each do |factory|
  require factory
end
class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  private
  def stub_authentication
    @controller.stubs(:authenticate).returns(true)
  end

  def dummy_html_response(response_name)
    IO.read(File.join([RAILS_ROOT + "/test/fixtures/dummy_responses/#{response_name}.html"]))
  end

  def dummy_xml_response(response_name)
    IO.read(File.join([RAILS_ROOT + "/test/fixtures/dummy_responses/#{response_name}.xml"]))
  end

  def dummy_csv_data(response_name)
    IO.read(File.join([RAILS_ROOT + "/test/fixtures/dummy_responses/#{response_name}.csv"]))
  end

  def dummy_json_response(response_name)
    IO.read(File.join([RAILS_ROOT + "/test/fixtures/dummy_responses/#{response_name}.json"]))
  end

  # These two methods allow you to use assert_select on an xml document without getting errors all over the place. Taken from http://weblog.jamisbuck.org/2007/1/4/assert_xml_select
  def xml_document
    @xml_document ||= HTML::Document.new(@response.body, false, true)
  end
  
  def assert_xml_select(*args, &block)
    @html_document = xml_document
    assert_select(*args, &block)
  end
  
end
