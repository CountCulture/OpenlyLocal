require 'test_helper'

class SupplierDetailsTest < ActiveSupport::TestCase
  
  context "A SupplierDetails instance" do
    setup do
      @supplier_details = SupplierDetails.new
    end
    
    should 'have url accessor' do
      assert @supplier_details.respond_to?(:url)
      assert @supplier_details.respond_to?(:url=)
    end
    
    should 'have source_url accessor' do
      assert @supplier_details.respond_to?(:source_for_info)
      assert @supplier_details.respond_to?(:source_for_info=)
    end
    
    should 'have wikipedia_url accessor' do
      assert @supplier_details.respond_to?(:wikipedia_url)
      assert @supplier_details.respond_to?(:wikipedia_url=)
    end
    
    should 'have resource_uri accessor' do
      assert @supplier_details.respond_to?(:resource_uri)
      assert @supplier_details.respond_to?(:resource_uri=)
    end
    
    context "when assigning url" do

      should "clean up using url_normaliser" do
        assert_equal 'http://foo.com', SupplierDetails.new(:url => 'foo.com').url
      end
    end
    
    context 'when approving' do
      setup do
        @item = Factory(:supplier)
        # @user_submission = Factory(:user_submission, :item => @item, :submission_type => 'supplier_details', :submission_details => {:company_number => '1234', :url => 'http://foo.com'})
        # @supplier_details_object = @user_submission.submission_details
      end
      
      context "in general" do
        setup do
          @entity = Factory(:charity)
          @user_submission = Factory(:user_submission, :item => @item, :submission_type => 'supplier_details', :submission_details => {:entity_type => 'Charity', :entity_id => @entity.id})
          @supplier_details_object = @user_submission.submission_details
        end

        should 'update item associated with user_submission with supplier details' do
          @item.expects(:update_supplier_details).with(@supplier_details_object)
          @supplier_details_object.approve(@user_submission)
        end

        should 'return true if item successfully updated' do
          @item.expects(:update_supplier_details).with(@supplier_details_object).returns(true)
          assert @supplier_details_object.approve(@user_submission)
        end

      end
      
      context "and company details supplied" do
        setup do
          @user_submission = Factory(:user_submission, :item => @item, :submission_type => 'supplier_details', :submission_details => {:company_number => '1234', :url => 'http://foo.com'})
          @supplier_details_object = @user_submission.submission_details
        end

        should 'update item associated with user_submission with supplier details' do
          @item.expects(:update_supplier_details).with(@supplier_details_object)

          @supplier_details_object.approve(@user_submission)
        end

        should 'return true if item successfully updated' do
          @item.expects(:update_supplier_details).with(@supplier_details_object).returns(true)
          assert @supplier_details_object.approve(@user_submission)
        end

        context "and problem updating from user_submission" do
          setup do
            @item.stubs(:update_supplier_details).with(@supplier_details_object).raises
          end

          should "not raise exception" do
            assert_nothing_raised(Exception) { @supplier_details_object.approve(@user_submission) }
          end

          should "return false" do
            assert !@supplier_details_object.approve(@user_submission)
          end
        end
      end
    end

  end
end