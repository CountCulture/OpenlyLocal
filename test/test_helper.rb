ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'test_help'
require File.expand_path('../test_models/test_models', __FILE__)
require 'factory_girl'
require 'mocha'
# Dir.glob(File.dirname(__FILE__) + "/factories/*").each do |factory|
#   require factory
# end
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

  def stub_authentication_with_user_auth_level(user_auth_level)
    @controller.stubs(:authenticated_users).returns({"dummy_user" => ["password1", user_auth_level.to_sym]})
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("dummy_user:password1")
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

# To avoid deprecation warnings from using assert_sent_email, we must switch to
# the have_sent_email matcher. However, the have_sent_email matcher in Shoulda 2
# cannot refer to instance variables. Unfortunately, we can't upgrade Shoulda 3
# because we use the obsolete should_change_record_count_of, should_change and
# should_not_change methods. We therefore apply the following patch.
# @see https://github.com/thoughtbot/shoulda-matchers/pull/13
module Shoulda
  module ActionMailer
    module Matchers
      def have_sent_email
        HaveSentEmailMatcher.new(self)
      end

      class HaveSentEmailMatcher
        def initialize(context)
          @context = context
        end

        def in_context(context)
          @context = context
          self
        end

        def with_subject(email_subject = nil, &block)
          @email_subject = email_subject
          @email_subject_block = block
          self
        end

        def from(sender = nil, &block)
          @sender = sender
          @sender_block = block
          self
        end

        def with_body(body = nil, &block)
          @body = body
          @body_block = block
          self
        end

        def to(recipient = nil, &block)
          @recipient = recipient
          @recipient_block = block
          self
        end

        def matches?(subject)
          normalize_blocks
          ::ActionMailer::Base.deliveries.each do |mail|
            @subject_failed = !regexp_or_string_match(mail.subject, @email_subject) if @email_subject
            @body_failed = !regexp_or_string_match(mail.body, @body) if @body
            @sender_failed = !regexp_or_string_match_in_array(mail.from, @sender) if @sender
            @recipient_failed = !regexp_or_string_match_in_array(mail.to, @recipient) if @recipient
            return true unless anything_failed?
          end

          false
        end

        def normalize_blocks
          @email_subject = @context.instance_eval(&@email_subject_block) if @email_subject_block
          @sender = @context.instance_eval(&@sender_block) if @sender_block
          @body = @context.instance_eval(&@body_block) if @body_block
          @recipient = @context.instance_eval(&@recipient_block) if @recipient_block
        end
      end
    end
  end
end
