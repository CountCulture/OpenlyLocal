require "test_helper"

class TestModel <ActiveRecord::Base
  attr_accessor :council
  include ScrapedModel::Base
  set_table_name "committees"
  has_many :test_child_models, :class_name => "TestChildModel", :foreign_key => "committee_id"
  has_many :test_join_models, :foreign_key => "committee_id"
  has_many :test_joined_models, :through => :test_join_models
  validates_presence_of :uid
  allow_access_to :test_child_models, :via => [:url, :uid]
end

class TestChildModel <ActiveRecord::Base
  belongs_to :test_model, :class_name => "TestModel", :foreign_key => "committee_id"
  AssociationAttributes = [:uid, :url]
  attr_accessor :council
  include ScrapedModel::Base
  set_table_name "meetings"
  allow_access_to :test_model, :via => [:uid, :title]
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
      @params = {:uid => 2, :url => "http:/some.url"} # uid and council_id can be anything as we stub finding of existing member
    end

    should "respond to association_extension_attributes" do
      assert TestModel.respond_to?(:association_extension_attributes)
    end
    
    should "return :uid by default for association_extension_attributes" do
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

      should "replace existing child objects with ones identified by council id and attribute" do
        @test_model.test_child_model_urls = ["bar.com"]
        assert_equal [@new_child], @test_model.test_child_models
        @test_model.test_child_model_uids = [@child.uid]
        assert_equal [@child], @test_model.test_child_models.reload
      end

      # should "return new associated objects when replacing existing ones" do
      #   # keeps same behaviour as usual AR
      #   assert_equal [@new_child], (@test_model.test_child_model_urls = ["bar.com"])
      # end

      context "and using normalised_method to access it" do
        # using HMT assoc to access TestModel#normalised_title attribute
        setup do
          @joined_model = TestJoinedModel.create!(:uid => 33, :council_id => 99 )
        end

        should "normalise attributes when finding_them" do
          @joined_model.test_model_normalised_titles = ["The Foo COmmittee"]
          assert_equal [@test_model], @joined_model.test_models
        end
      end 
      
      context "and model has belongs_to relationship" do
         should "add reader methods via relationship" do
           assert @child.respond_to?(:test_model_uid)
           assert @child.respond_to?(:test_model_title)
        end 
        
        should "return associated_objects identified by council and attribute" do
          assert_equal "Foo  Committee", @child.test_model_title
        end

        should "add writer methods via relationship" do
          assert @child.respond_to?(:test_model_uid=)
          assert @child.respond_to?(:test_model_title=)
        end 

        should "replace existing parent objects with one identified by council id and attribute" do
          @child.test_model_uid = 34
          assert_equal @another_test_model, @child.test_model
        end
        
        should "replace existing parent objects in DB with one identified by council id and attribute" do
          # NB THIS IS DIFFERENT FROM USUAL ActiveRecord BEHAVIOUR BUT MUCH FOR USEFUL GIVEN HOW IT IS USED
          @child.test_model_uid = 34
          assert_equal @another_test_model, @child.test_model.reload
        end

        # should "return new associated object when replacing existing one" do
        #   # keeps same behaviour as usual AR
        #   assert_equal @another_test_model, (@child.test_model_uid = 34)
        # end

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
    
    context "when finding all existing records from params by default" do
      should "find all restricted to council given in params" do
        TestModel.expects(:find_all_by_council_id).with(123)
        TestModel.find_all_existing(:council_id => 123)
      end
      
      should "raise exception if no council_id in params" do
        assert_raise(ArgumentError) { TestModel.find_all_existing({}) }
      end
    end
    
    context "record_not_found_behaviour" do
      should "by default create new instance from params" do
        assert_equal TestModel.new(:title => "bar").attributes, TestModel.record_not_found_behaviour(:title => "bar").attributes
      end
    end
    
    should "should have orphan_record_callback method" do
      assert TestModel.respond_to?(:orphan_records_callback)
    end
    
    context "when building_or_updating from params" do
      setup do
        TestModel.stubs(:find_all_existing).returns([@test_model, @another_test_model])
      end
      
      # should "should use existing record if it exists" do
      #   TestModel.expects(:find_existing).returns(@test_model)
      #   
      #   TestModel.build_or_update([@params], :council_id=>99)
      # end
      
      should "find all existing records using given council_id and first params in array" do
        TestModel.expects(:find_all_existing).with(@params.merge(:council_id => 42)).returns([])
        TestModel.build_or_update([@params], :council_id => 42)
      end
      
      should "match params against existing records" do
        # TestModel.stubs(:find_all_existing).returns([@test_model, @another_test_model])
        @test_model.expects(:matches_params).with(@params) # @params[:uid] == 2
        @another_test_model.expects(:matches_params).with(@params) #first existing one didn't match so tries next one
        TestModel.build_or_update([@params], :council_id => 42)
      end
      
      should "use matched record to be updated" do
        # TestModel.stubs(:find_all_existing).returns([@test_model, @another_test_model])
        @test_model.expects(:matches_params).returns(true)
        @another_test_model.expects(:matches_params).never # @test_model is matched so never tests @another_test_model
        TestModel.build_or_update([@params], :council_id => 42)
      end
      
      should "update matched record" do
        # TestModel.stubs(:find_all_existing).returns([@test_model, @another_test_model])
        @test_model.expects(:matches_params).returns(true)
        TestModel.build_or_update([@params], :council_id => 42)
        assert_equal "http:/some.url", @test_model.url
      end
      
      should "return matched record" do
        # TestModel.stubs(:find_existing).returns(@test_model)
        @test_model.expects(:matches_params).returns(true)
        
        assert_equal [@test_model], TestModel.build_or_update([@params], :council_id => 42)
      end
      
      should "update existing record" do
        TestModel.stubs(:find_existing).returns(@test_model)
        rekord = TestModel.build_or_update([@params], {:council_id => 99}).first
        assert_equal 99, rekord.council_id
        assert_equal "http:/some.url", rekord.url
      end
      
      should "build with attributes for new member when existing not found" do
        TestModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        TestModel.expects(:new).with(@params.merge(:council_id => 99)).returns(stub(:valid? => true))
        
        TestModel.build_or_update([@params], :council_id=>99)
      end
      
      should "return new record when existing not found" do
        TestModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        dummy_new_record = stub(:valid? => true)
        TestModel.stubs(:new).returns(dummy_new_record)
        
        assert_equal [dummy_new_record], TestModel.build_or_update([@params], :council_id=>99)
      end
      
      should "use params and council_id to create new record" do
        TestModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        TestModel.expects(:new).with(@params.merge(:council_id => 99)).returns(stub(:valid? => true))
        TestModel.build_or_update([@params], {:council_id => 99})
      end
      
      should "validate new records by default" do
        TestModel.stubs(:find_existing) # => returns nil
        
        assert_equal "can't be blank", TestModel.build_or_update([{:uid => ""}], :council_id=>99).first.errors[:uid]
      end
      
      should "validate existing records by default" do
        TestModel.stubs(:find_existing).returns(@test_model)
        
        assert_equal "can't be blank", TestModel.build_or_update([{:uid => ""}], :council_id=>99).first.errors[:uid]
      end
      
      should "save existing records if requested" do
        @test_model.expects(:matches_params).returns(true)
        
        TestModel.build_or_update([{:title => "new title"}], {:save_results => true, :council_id=>99})
        assert_equal "new title", @test_model.reload.title
      end
      
      should "save new records if requested" do
        TestModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        new_record = TestModel.build_or_update([@params], {:save_results => true, :council_id=>99}).first
        assert !new_record.new_record?
        assert new_record.new_record_before_save?
        assert_equal "http:/some.url", new_record.url
      end
      
      should "save new records using save_without_losing_dirty" do
        TestModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        TestModel.any_instance.expects(:save_without_losing_dirty)
        new_record = TestModel.build_or_update([@params], {:save_results => true, :council_id=>99})
      end

    end
    
    context "when building_or_updating from several params" do
      setup do
        TestModel.stubs(:find_all_existing).returns([@test_model, @another_test_model])
        @other_params = { :uid => 999, :url => "http://other.url", :title => "new title" } # uid and council_id can be anything as we stub finding of existing member
      end
      
      should "should use existing records" do
        TestModel.expects(:find_all_existing).returns([@test_model, @another_test_model])
              
        TestModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "return existing records that match params" do
        @test_model.stubs(:matches_params)
        @another_test_model.stubs(:matches_params).returns(true).then.returns(false)
        
        rekords = TestModel.build_or_update([@params, @other_params], :council_id=>99)
        assert_equal @another_test_model, rekords.first
        assert_kind_of TestModel, rekords.last
        assert rekords.last.new_record?
      end
      
      should "update existing records" do
        @test_model.stubs(:matches_params).returns(true).then.returns(false) 
        @another_test_model.stubs(:matches_params).returns(true)  
        TestModel.build_or_update([@params, @other_params], :council_id=>99).first
        assert_equal "http:/some.url", @test_model.url
        assert_equal "http://other.url", @another_test_model.url
      end
      
      should "should build with attributes for new member when no existing found" do
        TestModel.any_instance.stubs(:matches_params)
        TestModel.expects(:new).with(@params.merge(:council_id => 99)).returns(stub(:valid? => true))
        TestModel.expects(:new).with(@other_params.merge(:council_id => 99)).returns(stub(:valid? => true))
        
        TestModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "should build with attributes for new member when some existing not found" do
        @test_model.stubs(:matches_params).returns(true).then.returns(false)
        @another_test_model.expects(:matches_params) # => false
        TestModel.expects(:new).with(@params.merge(:council_id => 99)).never
        TestModel.expects(:new).with(@other_params.merge(:council_id => 99)).returns(stub(:valid? => true))
        
        TestModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "should return new record when no existing found" do
        dummy_new_record1, dummy_new_record2 = stub(:valid? => true), stub(:valid? => true)
        TestModel.stubs(:new).returns(dummy_new_record1).then.returns(dummy_new_record2)
        
        assert_equal [dummy_new_record1, dummy_new_record2], TestModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "should return new record when some existing not found" do
        @test_model.expects(:matches_params).twice.returns(false).then.returns(true)
        dummy_new_record1, dummy_new_record2 = stub(:valid? => true), stub(:valid? => true)
        TestModel.stubs(:new).returns(dummy_new_record1)
        
        assert_equal [dummy_new_record1, @test_model], TestModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "should execute record_not_found_behaviour when some existing not found" do
        dummy_new_record1, dummy_new_record2 = stub(:valid? => true), stub(:valid? => true)
        TestModel.expects(:record_not_found_behaviour).with(@params.merge(:council_id => 99)).returns(dummy_new_record1)
        TestModel.expects(:record_not_found_behaviour).with(@other_params.merge(:council_id => 99)).returns(dummy_new_record2)
        
        TestModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should_eventually "execute orphan_records_callback on records not returned by scraper" do
        # TestModel.stubs(:find_existing).returns(nil).then.returns(@another_test_model)
        # dummy_new_record1, dummy_new_record2 = stub(:valid? => true), stub(:valid? => true)
        # TestModel.expects(:record_not_found_behaviour).with(@params.merge(:council_id => 99)).returns(dummy_new_record1)
        # 
        # TestModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
    end
    
    # context "when creating_or_update_and_saving from params" do
    # 
    #   context "with existing record" do
    #     setup do
    #       @dummy_record = stub_everything
    #     end
    #     
    #     should "build_or_update on class" do
    #       TestModel.expects(:build_or_update).with(@params).returns(@dummy_record)
    #       TestModel.create_or_update_and_save(@params)
    #     end
    #     
    #     should "save_without_losing_dirty on record built or updated" do
    #       TestModel.stubs(:build_or_update).returns(@dummy_record)
    #       @dummy_record.expects(:save_without_losing_dirty)
    #       TestModel.create_or_update_and_save(@params)
    #     end
    #     
    #     should "return updated record" do
    #       TestModel.stubs(:build_or_update).returns(@dummy_record)
    #       assert_equal @dummy_record, TestModel.create_or_update_and_save(@params)
    #     end
    #     
    #     should "not raise exception if saving fails" do
    #       TestModel.stubs(:build_or_update).returns(@dummy_record)
    #       @dummy_record.stubs(:save_without_losing_dirty)
    #       assert_nothing_raised() { TestModel.create_or_update_and_save(@params) }
    #     end
    #   end
    # end
    # 
    # context "when creating_or_update_and_saving! from params" do
    #   setup do
    #     @dummy_record = stub_everything
    #     @dummy_record.stubs(:save_without_losing_dirty).returns(true)
    #   end
    #         
    #   should "build_or_update on class" do
    #     TestModel.expects(:build_or_update).with(@params).returns(@dummy_record)
    #     TestModel.create_or_update_and_save!(@params)
    #   end
    #   
    #   should "save_without_losing_dirty on record built or updated" do
    #     TestModel.stubs(:build_or_update).returns(@dummy_record)
    #     @dummy_record.expects(:save_without_losing_dirty).returns(true)
    #     TestModel.create_or_update_and_save!(@params)
    #   end
    #   
    #   should "return updated record" do
    #     TestModel.stubs(:build_or_update).returns(@dummy_record)
    #     assert_equal @dummy_record, TestModel.create_or_update_and_save!(@params)
    #   end
    #   
    #   should "raise exception if saving fails" do
    #     TestModel.stubs(:build_or_update).returns(@dummy_record)
    #     @dummy_record.stubs(:save_without_losing_dirty)
    #     assert_raise(ActiveRecord::RecordNotSaved) {  TestModel.create_or_update_and_save!(@params) }
    #   end
    # end

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
   
    should "return nil for status by default" do
      assert_nil @test_model.status
    end
    
    should "calulate openlylocal_url from table name" do
      assert_equal "http://#{DefaultDomain}/committees/#{@test_model.to_param}", @test_model.openlylocal_url
    end
    
    should "match params based on uid default" do
      test_model = TestModel.new(:uid => "bar")
      assert !test_model.matches_params()
      assert !test_model.matches_params(:uid => nil)
      assert !test_model.matches_params(:uid => "foo")
      # assert !test_model.matches_params(:council_id => 42, :uid => "foo")
      # assert !test_model.matches_params(:council_id => 99, :uid => "bar")
      assert test_model.matches_params(:uid => "bar")
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
 
end
