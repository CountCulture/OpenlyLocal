require "test_helper"

class TestModel <ActiveRecord::Base
  attr_accessor :council
  include ScrapedModel::Base
  set_table_name "committees"
  has_many :test_child_models, :class_name => "TestChildModel", :foreign_key => "committee_id", :extend => ScrapedModel::UidAssociationExtension
  has_many :test_join_models, :foreign_key => "committee_id"
  has_many :test_joined_models, :through => :test_join_models, :extend => ScrapedModel::UidAssociationExtension
  allow_access_to :test_child_models, :via => [:url, :uid]
end

class TestChildModel <ActiveRecord::Base
  AssociationAttributes = [:uid, :url]
  attr_accessor :council
  include ScrapedModel::Base
  set_table_name "meetings"
end

class TestJoinModel <ActiveRecord::Base
  set_table_name "memberships"
  belongs_to :test_model, :class_name => "TestModel", :foreign_key => "committee_id"
  belongs_to :test_joined_model, :foreign_key => "member_id"
end

class TestJoinedModel <ActiveRecord::Base
  attr_accessor :council
  include ScrapedModel::Base
  set_table_name "members"
  has_many :test_join_models, :foreign_key => "member_id"
  has_many :test_models, :through => :test_join_models
  allow_access_to :test_models, :via => [:uid, :normalised_title]
end

class ScrapedModelTest < ActiveSupport::TestCase
  
  context "A class that includes ScrapedModel Base mixin" do
    setup do
      TestModel.delete_all # doesn't seem to delete old records !?!
      @test_model = TestModel.create!(:uid => 33, :council_id => 99, :title => "Foo  Committee", :normalised_title => "foo")
      @another_test_model = TestModel.create!(:uid => 34, :council_id => 99, :title => "Bar Committee")
      @params = {:uid => 2, :council_id => 2, :url => "http:/some.url"} # uid and council_id can be anything as we stub finding of existing member
    end

    should "respond to association_extension_attributes" do
      assert TestModel.respond_to?(:association_extension_attributes)
    end
    
    should "return ;uid by default for association_extension_attributes" do
      assert_equal [:uid], TestModel.association_extension_attributes
    end

    should "return array of association_extension_attributes if defined" do
      assert_equal [:uid, :url], TestChildModel.association_extension_attributes
    end
    
    should "have allow_access_to class method" do
      assert TestModel.respond_to?(:allow_access_to)
    end

    context "when allowing access to given relationship" do
      setup do
        @test_model.test_child_models << @child = TestChildModel.create!(:uid => 33, :council_id => @test_model.council_id, :url => "foo.com")
        @new_child = TestChildModel.create!(:uid => 34, :council_id => @test_model.council_id, :url => "bar.com")
        @another_council_child = TestModel.create!(:uid => 44, :council_id => 10, :url => "bar.com")
      end

       should "add reader methods via relationship" do
        assert @test_model.respond_to?(:test_child_model_urls)
        assert @test_model.respond_to?(:test_child_model_uids)
      end 
      
      should "return associated_objects identified by council and attribute" do
        assert_equal ["foo.com"], @test_model.test_child_model_urls
      end

      should "add writer methods via relationship" do
        assert @test_model.respond_to?(:test_child_model_urls=)
        assert @test_model.respond_to?(:test_child_model_uids=)
      end 

      should "given replace existing child objects with ones identified by council id and attribute" do
        @test_model.test_child_model_urls = ["bar.com"]
        assert_equal [@new_child], @test_model.test_child_models
        @test_model.test_child_model_uids = [@child.uid]
        assert_equal [@child], @test_model.test_child_models.reload
      end

      context "and using normalised_method to access it" do
        # using HMT assoc to access TestModel#normalised_title attribute
        setup do
          @joined_model = TestJoinedModel.create!(:uid => 33, :council_id => 99 )
        end

        should "normalise attributes when finding_them" do
          # p @joined_model.test_models
          @joined_model.test_model_normalised_titles = ["The Foo COmmittee"]
          assert_equal [@test_model], @joined_model.test_models
        end
      end 
 
    end

   context "when finding existing member from params" do

      should "should return member which has given uid and council" do
        assert_equal @test_model, TestModel.find_existing(:uid => @test_model.uid, :council_id => @test_model.council_id)
      end
        
      should "should return nil when uid is blank" do
        @test_model.update_attribute(:uid, nil) # make sure there's already a record with nil uid so we can check it WON'T be returned
        assert_nil TestModel.find_existing(:uid => nil, :council_id => @test_model.council_id )
      end
      
      should "should return nil when council_id is blank" do
        @test_model.update_attribute(:council_id, nil)
        assert_nil TestModel.find_existing(:uid => @test_model.uid, :council_id => nil)
      end
      
      should "should return nil when no record with given uid and council" do
        assert_nil TestModel.find_existing(:uid => @test_model.uid, :council_id => 42)
      end
    end
    
    context "when building_or_updating from params" do
      setup do
      end
      
      should "should use existing record if it exists" do
        TestModel.expects(:find_existing).returns(@test_model)
        
        TestModel.build_or_update(@params)
      end
      
      should "return existing record if it exists" do
        TestModel.stubs(:find_existing).returns(@test_model)
        
        rekord = TestModel.build_or_update(@params)
        assert_equal @test_model, rekord
      end
      
      should "update existing record" do
        TestModel.stubs(:find_existing).returns(@test_model)
        rekord = TestModel.build_or_update(@params)
        assert_equal 2, rekord.council_id
        assert_equal "http:/some.url", rekord.url
      end
      
      should "should build with attributes for new member when existing not found" do
        TestModel.stubs(:find_existing) # => returns nil
        TestModel.expects(:new).with(@params)
        
        TestModel.build_or_update(@params)
      end
      
      should "should return new record when existing not found" do
        TestModel.stubs(:find_existing) # => returns nil
        dummy_new_record = stub
        TestModel.stubs(:new).returns(dummy_new_record)
        
        assert_equal dummy_new_record, TestModel.build_or_update(@params)
      end
      
    end
    
    context "when creating_or_update_and_saving from params" do

      context "with existing record" do
        setup do
          @dummy_record = stub_everything
        end
        
        should "build_or_update on class" do
          TestModel.expects(:build_or_update).with(@params).returns(@dummy_record)
          TestModel.create_or_update_and_save(@params)
        end
        
        should "save_without_losing_dirty on record built or updated" do
          TestModel.stubs(:build_or_update).returns(@dummy_record)
          @dummy_record.expects(:save_without_losing_dirty)
          TestModel.create_or_update_and_save(@params)
        end
        
        should "return updated record" do
          TestModel.stubs(:build_or_update).returns(@dummy_record)
          assert_equal @dummy_record, TestModel.create_or_update_and_save(@params)
        end
        
        should "not raise exception if saving fails" do
          TestModel.stubs(:build_or_update).returns(@dummy_record)
          @dummy_record.stubs(:save_without_losing_dirty)
          assert_nothing_raised() { TestModel.create_or_update_and_save(@params) }
        end
      end
    end

    context "when creating_or_update_and_saving! from params" do
      setup do
        @dummy_record = stub_everything
        @dummy_record.stubs(:save_without_losing_dirty).returns(true)
      end
            
      should "build_or_update on class" do
        TestModel.expects(:build_or_update).with(@params).returns(@dummy_record)
        TestModel.create_or_update_and_save!(@params)
      end
      
      should "save_without_losing_dirty on record built or updated" do
        TestModel.stubs(:build_or_update).returns(@dummy_record)
        @dummy_record.expects(:save_without_losing_dirty).returns(true)
        TestModel.create_or_update_and_save!(@params)
      end
      
      should "return updated record" do
        TestModel.stubs(:build_or_update).returns(@dummy_record)
        assert_equal @dummy_record, TestModel.create_or_update_and_save!(@params)
      end
      
      should "raise exception if saving fails" do
        TestModel.stubs(:build_or_update).returns(@dummy_record)
        @dummy_record.stubs(:save_without_losing_dirty)
        assert_raise(ActiveRecord::RecordNotSaved) {  TestModel.create_or_update_and_save!(@params) }
      end
    end

  end
 
  context "An instance of a class that includes ScrapedModel Base mixin" do
    setup do
      @test_model = TestModel.new(:uid => 42)
    end
    
    should "provide access to new_record_before_save instance variable" do
      @test_model.instance_variable_set(:@new_record_before_save, true)
      assert @test_model.new_record_before_save?
    end
    
    should "save_without_losing_dirty" do
      assert @test_model.respond_to?(:save_without_losing_dirty)
    end
    
    should "escape title in to_param_method" do
      @test_model.save!
      @test_model.stubs(:title => "some title-with/stuff")
      assert_equal "#{@test_model.id}-some-title-with-stuff", @test_model.to_param
    end
    
    should "return nil for to_param_method if id not set" do
      @test_model.stubs(:title => "some title-with/stuff")
      assert_nil @test_model.to_param
    end
   
    context "when saving_without_losing_dirty" do
      setup do
        @test_model.save_without_losing_dirty
      end
      
      should_change "TestModel.count", :by => 1
      should "save record" do
        assert !@test_model.new_record?
      end
      
      should "keep record of new attributes" do
        assert_equal [nil, 42], @test_model.changes['uid']
      end
      
      should "return true if successfully saves" do
        @test_model.expects(:save).returns(true)
        assert @test_model.save_without_losing_dirty
      end
      
      should "return false if does not successfully save" do
        @test_model.expects(:save).returns(false)
        assert !@test_model.save_without_losing_dirty
      end
      
    end
   
    context "with an associated council" do
      setup do
        @council = Factory(:council)
        @test_model.council = @council
        Council.record_timestamps = false # update timestamp without triggering callbacks
        @council.update_attributes(:updated_at => 2.days.ago) #... though thought from Rails 2.3 you could do this without turning off timestamps
        Council.record_timestamps = true
      end
    
      should "mark council as updated when item is updated" do
        @test_model.update_attribute(:title, "Foo")
        assert_in_delta Time.now, @council.updated_at, 2
      end
      should "mark council as updated when item is deleted" do
        @test_model.destroy
        assert_in_delta Time.now, @council.updated_at, 2
      end
    end
  end
 
  context "An instance of a class extends has_many relationship with ScrapedModel UidAssociationExtension" do
    context "with child objects" do
      setup do
        @parent = TestModel.create!(:uid => 33, :council_id => 9)
        @parent.test_child_models << @child = TestChildModel.create!(:uid => 33, :council_id => 9)
        @new_child = TestChildModel.create!(:uid => 34, :council_id => 9, :url => "foo.com/child")
        @another_council_child = TestModel.create!(:uid => 44, :council_id => 10)
      end
 
      should "return child uids" do
        assert_equal [@child.uid], @parent.test_child_models.uids
      end
      
      should "replace existing children with ones with given uids" do
        @parent.test_child_models.uids = [@new_child.uid]
        assert_equal [@new_child], @parent.test_child_models
      end
      
      should "not add children that don't exist for council" do
        @parent.test_child_models.uids = [@another_council_child.uid]
        assert_equal [], @parent.test_child_models
      end

      # should "add reader methods relating to attributes in AssociationAttributes" do
      #   assert_equal [@child.url], @parent.test_child_models.urls
      # end

     #  should "add writer methods relating to attributes in AssociationAttributes" do
      #   @parent.test_child_models.urls = [@new_child.url]
      #   assert_equal [@new_child], @parent.test_child_models
      #  end
    end
  end
  
  context "An instance of a class extends has_many through relationship with ScrapedModel UidAssociationExtension" do
    
    context "with joined objects" do
      setup do
        @parent = TestModel.create!(:uid => 33, :council_id => 9)
        @parent.test_joined_models << @joined_model = TestJoinedModel.create!(:uid => 33, :council_id => 9)
        @new_joined_model = TestJoinedModel.create!(:uid => 34, :council_id => 9)
        @another_council_joined_model = TestJoinedModel.create!(:uid => 44, :council_id => 10)
      end
   
      should "return joined objects uids" do
        assert_equal [@joined_model.uid], @parent.test_joined_models.uids
      end
   
      should "replace existing joined objects with ones with given uids" do
        @parent.test_joined_models.uids = [@new_joined_model.uid]
        assert_equal [@new_joined_model], @parent.test_joined_models
      end
   
      should "not add joined objects that don't exist for council" do
        @parent.test_joined_models.uids = [@another_council_joined_model.uid]
        assert_equal [], @parent.test_joined_models
      end
    end
  end
end
