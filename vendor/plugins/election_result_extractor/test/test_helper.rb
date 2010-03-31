$:.unshift File.join(File.dirname(__FILE__), '..', 'vendor', 'sinatra', 'lib')
require 'rubygems'

module TestHelper
  
  def dummy_response(response_name)
    IO.read(File.join(File.dirname(__FILE__), 'dummy_responses', response_name.to_s))
  end

end

require 'test/unit'
require 'shoulda'
require 'mocha'

Test::Unit::TestCase.send(:include, TestHelper)
