require 'test_helper'

class CharityWorkerTest < ActiveSupport::TestCase
  
  context "CharityWorker" do
    setup do
      @charity = Factory(:charity)
      @charity_worker = CharityWorker.new(@charity, :foo_method)
    end
    
    context "on instantiation" do

      should "should store charity id as charity_id" do
        assert_equal @charity.id, @charity_worker.charity_id
      end

      should "should store given method as delayed_meth" do
        assert_equal :foo_method, @charity_worker.delayed_meth
      end
    end

    context 'when asked to perform' do

      should 'run delayed_meth on charity identified by charity_id' do
        Charity.expects(:find).with(@charity.id).returns(@charity)
        @charity.expects(:foo_method)
        @charity_worker.perform
      end

    end

  end

end