require "test_helper"

class ScrapedModelTest < ActiveSupport::TestCase
  
  context "A class that includes ScrapedModel Base mixin" do
    setup do
      TestScrapedModel.delete_all # doesn't seem to delete old records !?!
      @test_model = TestScrapedModel.create!(:uid => 33, :council_id => 99, :title => "Foo  Committee", :normalised_title => "foo committee")
      @another_test_model = TestScrapedModel.create!(:uid => 34, :council_id => 99, :title => "Bar Committee")
      @params = {:uid => 2, :url => "http:/some.url"} # uid and council_id can be anything as we stub finding of existing member
    end

    should "respond to association_extension_attributes" do
      assert TestScrapedModel.respond_to?(:association_extension_attributes)
    end
    
    should "return :uid by default for association_extension_attributes" do
      assert_equal [:uid], TestScrapedModel.association_extension_attributes
    end

    should "return array of association_extension_attributes if defined" do
      assert_equal [:uid, :url], TestChildModel.association_extension_attributes
    end
    
    should "have normalise_title class method" do
      assert TestScrapedModel.respond_to?(:normalise_title)
    end

    should "by default use TitleNormalizer to normalize title" do
      TitleNormaliser.expects(:normalise_title).with("foo").returns("bar")
      assert_equal "bar", TestScrapedModel.normalise_title("foo")
    end

    should "have allow_access_to class method" do
      assert TestScrapedModel.respond_to?(:allow_access_to)
    end

    context "when allowing access to given relationship" do
      setup do
        @test_model.test_child_models << @child = TestChildModel.create!(:uid => 33, :council_id => @test_model.council_id, :url => "foo.com")
        @new_child = TestChildModel.create!(:uid => 34, :council_id => @test_model.council_id, :url => "bar.com")
        @another_council_child = TestScrapedModel.create!(:uid => 44, :council_id => 10, :url => "bar.com")
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
        # using HMT assoc to access TestScrapedModel#normalised_title attribute
        setup do
          @joined_model = TestJoinedModel.create!(:uid => 33, :council_id => 99 )
        end

        should "normalise attributes when finding_them" do
          @joined_model.test_scraped_model_normalised_titles = ["THE Foo - COmmittee"]
          assert_equal [@test_model], @joined_model.test_scraped_models
        end
      end 
      
      context "and model has belongs_to relationship" do
         should "add reader methods via relationship" do
           assert @child.respond_to?(:test_scraped_model_uid)
           assert @child.respond_to?(:test_scraped_model_title)
        end 
        
        should "return associated_objects identified by council and attribute" do
          assert_equal "Foo  Committee", @child.test_scraped_model_title
        end

        should "add writer methods via relationship" do
          assert @child.respond_to?(:test_scraped_model_uid=)
          assert @child.respond_to?(:test_scraped_model_title=)
        end 

        should "replace existing parent objects with one identified by council id and attribute" do
          @child.test_scraped_model_uid = 34
          assert_equal @another_test_model, @child.test_scraped_model
        end
        
        should "replace existing parent objects in DB with one identified by council id and attribute" do
          # NB THIS IS DIFFERENT FROM USUAL ActiveRecord BEHAVIOUR BUT MUCH MORE USEFUL GIVEN HOW IT IS USED
          @child.test_scraped_model_uid = 34
          assert_equal @another_test_model, @child.test_scraped_model.reload
        end

        # should "return new associated object when replacing existing one" do
        #   # keeps same behaviour as usual AR
        #   assert_equal @another_test_scraped_model, (@child.test_scraped_model_uid = 34)
        # end

      end
 
    end

    context "when finding all existing records from params by default" do
      should "find all restricted to council given in params" do
        TestScrapedModel.expects(:find_all_by_council_id).with(123)
        TestScrapedModel.find_all_existing(:council_id => 123)
      end
      
      should "raise exception if no council_id in params" do
        assert_raise(ArgumentError) { TestScrapedModel.find_all_existing({}) }
      end
    end
    
    context "record_not_found_behaviour" do
      should "by default create new instance from params" do
        assert_equal TestScrapedModel.new(:title => "bar").attributes, TestScrapedModel.send(:record_not_found_behaviour, :title => "bar").attributes
      end
    end
    
    should "should have orphan_record_callback method" do
      assert TestScrapedModel.respond_to?(:orphan_records_callback)
    end
    
    context "when building_or_updating from params" do
      setup do
        @dummy_new_record = valid_test_model
        TestScrapedModel.stubs(:find_all_existing).returns([@test_model, @another_test_model])
      end
      
      should "find all existing records using given council_id and first params in array" do
        TestScrapedModel.expects(:find_all_existing).with(@params.merge(:council_id => 42)).returns([])
        TestScrapedModel.build_or_update([@params], :council_id => 42)
      end
      
      should "match params against existing records" do
        @test_model.expects(:matches_params).with(@params) # @params[:uid] == 2
        @another_test_model.expects(:matches_params).with(@params) #first existing one didn't match so tries next one
        TestScrapedModel.build_or_update([@params], :council_id => 42)
      end
      
      should "use matched record to be updated" do
        @test_model.expects(:matches_params).returns(true)
        @another_test_model.expects(:matches_params).never # @test_model is matched so never tests @another_test_model
        TestScrapedModel.build_or_update([@params], :council_id => 42)
      end
      
      should "update matched record" do
        @test_model.expects(:matches_params).returns(true)
        TestScrapedModel.build_or_update([@params], :council_id => 42)
        assert_equal "http:/some.url", @test_model.url
      end
      
      should "return ScrapedObjectResult for matched record" do
        @test_model.expects(:matches_params).returns(true)
        
        assert_equal [ScrapedObjectResult.new(@test_model)], TestScrapedModel.build_or_update([@params], :council_id => 42)
      end
      
      should "update existing record" do
        rekord = TestScrapedModel.build_or_update([@params], {:council_id => 99}).first
        assert_equal "http:/some.url", rekord.url
      end
      
      should "build with attributes for new member when existing not found" do
        TestScrapedModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        TestScrapedModel.expects(:new).with(@params.merge(:council_id => 99)).returns(@dummy_new_record)
        
        TestScrapedModel.build_or_update([@params], :council_id=>99)
      end
      
      should "return new record when existing not found" do
        TestScrapedModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        TestScrapedModel.stubs(:new).returns(@dummy_new_record)
        
        assert_equal [ScrapedObjectResult.new(@dummy_new_record)], TestScrapedModel.build_or_update([@params], :council_id=>99)
      end
      
      should "use params and council_id to create new record" do
        TestScrapedModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        TestScrapedModel.expects(:new).with(@params.merge(:council_id => 99)).returns(@dummy_new_record)
        TestScrapedModel.build_or_update([@params], {:council_id => 99})
      end
      
      should "validate new records by default" do
        assert_equal "can't be blank", TestScrapedModel.build_or_update([{:uid => ""}], :council_id=>99).first.errors[:uid]
      end
      
      should "validate existing records by default" do
        @test_model.stubs(:matches_params).returns(true).then.returns(:false)
        assert_equal ScrapedObjectResult.new(@test_model), result = TestScrapedModel.build_or_update([{:uid => ""}], :council_id=>99).first
        assert_equal "can't be blank", @test_model.errors[:uid]
      end
      
      should "save existing records if requested" do
        @test_model.expects(:matches_params).returns(true)
        
        TestScrapedModel.build_or_update([{:title => "new title"}], {:save_results => true, :council_id=>99})
        assert_equal "new title", @test_model.reload.title
      end
      
      should "save new records if requested" do
        TestScrapedModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        new_rec = nil
        assert_difference "TestScrapedModel.count", 1 do 
          new_rec = TestScrapedModel.build_or_update([@params], {:save_results => true, :council_id=>99}).first
        end
        assert "new", new_rec.status
        assert_equal "http:/some.url", new_rec.url
      end
      
      should "save new records using save_without_losing_dirty" do
        TestScrapedModel.any_instance.expects(:matches_params).twice # overrides stubbing and returns nil
        TestScrapedModel.any_instance.expects(:save_without_losing_dirty)
        new_record = TestScrapedModel.build_or_update([@params], {:save_results => true, :council_id=>99})
      end

      should "execute orphan_records_callback on all records not matched by parsed params" do
        TestScrapedModel.any_instance.stubs(:matches_params) # => returns nil
        TestScrapedModel.expects(:orphan_records_callback).with([@test_model, @another_test_model], anything)
        TestScrapedModel.build_or_update([@params], :council_id=>99)
      end
      
      should "not execute orphan_records_callback on records matched by parsed params" do
        @test_model.stubs(:matches_params).returns(true)
        @another_test_model.stubs(:matches_params)
        TestScrapedModel.expects(:orphan_records_callback).with([@another_test_model], anything)
        TestScrapedModel.build_or_update([@params], :council_id=>99)
      end
            
      should "not execute orphan_records_callback on if no parsed params" do
        TestScrapedModel.expects(:orphan_records_callback).never
        TestScrapedModel.build_or_update([], :council_id=>99)
      end
            
      should "pass save_results flag to orphan_records_callback when true" do
        TestScrapedModel.any_instance.stubs(:matches_params) # => returns nil
        TestScrapedModel.expects(:orphan_records_callback).with(anything, {:save_results => true})
        TestScrapedModel.build_or_update([@params], :council_id=>99, :save_results => true)
      end
      
      should "pass save_results flag as nil to orphan_records_callback when not set" do
        TestScrapedModel.any_instance.stubs(:matches_params) # => returns nil
        TestScrapedModel.expects(:orphan_records_callback).with(anything, {:save_results => nil})
        TestScrapedModel.build_or_update([@params], :council_id=>99)
      end
      
    end
    
    context "when building_or_updating from several params" do
      setup do
        TestScrapedModel.stubs(:find_all_existing).returns([@test_model, @another_test_model])
        @other_params = { :uid => 999, :url => "http://other.url", :title => "new title" } # uid and council_id can be anything as we stub finding of existing member
        @dummy_new_record = valid_test_model
      end
      
      should "should use existing records" do
        TestScrapedModel.expects(:find_all_existing).returns([@test_model, @another_test_model])
              
        TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "return existing records that match params" do
        @test_model.stubs(:matches_params)
        @another_test_model.stubs(:matches_params).returns(true).then.returns(false)
        
        rekords = TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99)
        assert_equal ScrapedObjectResult.new(@another_test_model), rekords.first
        assert "new", rekords.last.status
      end
      
      should "update existing records" do
        @test_model.stubs(:matches_params).returns(true).then.returns(false) 
        @another_test_model.stubs(:matches_params).returns(true)  
        TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99).first
        assert_equal "http:/some.url", @test_model.url
        assert_equal "http://other.url", @another_test_model.url
      end
      
      should "should build with attributes for new member when no existing found" do
        TestScrapedModel.any_instance.stubs(:matches_params)
        TestScrapedModel.expects(:new).with(@params.merge(:council_id => 99)).returns(@dummy_new_record)
        TestScrapedModel.expects(:new).with(@other_params.merge(:council_id => 99)).returns(@dummy_new_record)
        
        TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "should build with attributes for new member when some existing not found" do
        @test_model.stubs(:matches_params).returns(true).then.returns(false)
        @another_test_model.expects(:matches_params) # => false
        TestScrapedModel.expects(:new).with(@params.merge(:council_id => 99)).never
        TestScrapedModel.expects(:new).with(@other_params.merge(:council_id => 99)).returns(@dummy_new_record)
        
        TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "should return ScrapedObjectResult for new records when no existing found" do
        dummy_new_record1, dummy_new_record2 = valid_test_model, valid_test_model
        TestScrapedModel.stubs(:new).returns(dummy_new_record1).then.returns(dummy_new_record2)
        
        assert_equal [ScrapedObjectResult.new(dummy_new_record1), ScrapedObjectResult.new(dummy_new_record2)], TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "should return ScrapedObjectResult for new record when some existing not found" do
        @test_model.expects(:matches_params).twice.returns(false).then.returns(true)
        dummy_new_record1, dummy_new_record2 = valid_test_model, valid_test_model
        TestScrapedModel.stubs(:new).returns(dummy_new_record1)
        
        assert_equal [ScrapedObjectResult.new(dummy_new_record1), ScrapedObjectResult.new(@test_model)], TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "should execute record_not_found_behaviour when some existing not found" do
        dummy_new_record1, dummy_new_record2 = valid_test_model, valid_test_model
        TestScrapedModel.expects(:record_not_found_behaviour).with(@params.merge(:council_id => 99)).returns(dummy_new_record1)
        TestScrapedModel.expects(:record_not_found_behaviour).with(@other_params.merge(:council_id => 99)).returns(dummy_new_record2)
        
        TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "execute orphan_records_callback on all records not matched by parsed params" do
        TestScrapedModel.any_instance.stubs(:matches_params) # => returns nil
        TestScrapedModel.expects(:orphan_records_callback).with([@test_model, @another_test_model], anything)
        TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99)
      end
      
      should "not execute orphan_records_callback on records matched by parsed params" do
        @test_model.stubs(:matches_params).returns(true).then.returns(:false)
        @another_test_model.stubs(:matches_params)
        TestScrapedModel.expects(:orphan_records_callback).with([@another_test_model], anything)
        TestScrapedModel.build_or_update([@params, @other_params], :council_id=>99)
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
    #       TestScrapedModel.expects(:build_or_update).with(@params).returns(@dummy_record)
    #       TestScrapedModel.create_or_update_and_save(@params)
    #     end
    #     
    #     should "save_without_losing_dirty on record built or updated" do
    #       TestScrapedModel.stubs(:build_or_update).returns(@dummy_record)
    #       @dummy_record.expects(:save_without_losing_dirty)
    #       TestScrapedModel.create_or_update_and_save(@params)
    #     end
    #     
    #     should "return updated record" do
    #       TestScrapedModel.stubs(:build_or_update).returns(@dummy_record)
    #       assert_equal @dummy_record, TestScrapedModel.create_or_update_and_save(@params)
    #     end
    #     
    #     should "not raise exception if saving fails" do
    #       TestScrapedModel.stubs(:build_or_update).returns(@dummy_record)
    #       @dummy_record.stubs(:save_without_losing_dirty)
    #       assert_nothing_raised() { TestScrapedModel.create_or_update_and_save(@params) }
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
    #     TestScrapedModel.expects(:build_or_update).with(@params).returns(@dummy_record)
    #     TestScrapedModel.create_or_update_and_save!(@params)
    #   end
    #   
    #   should "save_without_losing_dirty on record built or updated" do
    #     TestScrapedModel.stubs(:build_or_update).returns(@dummy_record)
    #     @dummy_record.expects(:save_without_losing_dirty).returns(true)
    #     TestScrapedModel.create_or_update_and_save!(@params)
    #   end
    #   
    #   should "return updated record" do
    #     TestScrapedModel.stubs(:build_or_update).returns(@dummy_record)
    #     assert_equal @dummy_record, TestScrapedModel.create_or_update_and_save!(@params)
    #   end
    #   
    #   should "raise exception if saving fails" do
    #     TestScrapedModel.stubs(:build_or_update).returns(@dummy_record)
    #     @dummy_record.stubs(:save_without_losing_dirty)
    #     assert_raise(ActiveRecord::RecordNotSaved) {  TestScrapedModel.create_or_update_and_save!(@params) }
    #   end
    # end

  end
 
  context "An instance of a class that includes ScrapedModel Base mixin" do
    setup do
      @test_model = TestScrapedModel.new(:uid => 42)
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
    
    should "calculate openlylocal_url from table name and to_param method" do
      assert_equal "http://#{DefaultDomain}/committees/#{@test_model.to_param}", @test_model.openlylocal_url
    end
    
    context "when returning resource_uri" do
      should 'return calculate from table_name and id' do
        assert_equal "http://#{DefaultDomain}/id/committees/#{@test_model.id}", @test_model.resource_uri
      end
    end
    
    should "match by default params based on uid" do
      test_model = TestScrapedModel.new(:uid => "bar")
      assert !test_model.matches_params()
      assert !test_model.matches_params(:uid => "foo")
      assert test_model.matches_params(:uid => "bar")
    end
    should "not by default match params based when uid is blank" do
      assert !TestScrapedModel.new(:uid => "bar").matches_params(:uid => nil)
      assert !TestScrapedModel.new.matches_params()
      assert !TestScrapedModel.new.matches_params(:uid => nil)
      assert !TestScrapedModel.new(:uid => "bar").matches_params(:uid => "")
      assert !TestScrapedModel.new(:uid => "").matches_params(:uid => "")
      assert !TestScrapedModel.new(:uid => "").matches_params()
    end
    
    context "when saving_without_losing_dirty" do
      setup do
        @test_model.save_without_losing_dirty
      end
      
      should_change "TestScrapedModel.count", :by => 1
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
  
  private
  def valid_test_model
    TestScrapedModel.create!(:uid => 33, :council_id => 99)
  end
 
end
