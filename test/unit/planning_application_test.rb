require 'test_helper'

class PlanningApplicationTest < ActiveSupport::TestCase
  subject { @planning_application }
  
  context "the PlanningApplication class" do
    setup do
      @planning_application = Factory(:planning_application)
    end
    
    should validate_presence_of :council_id
    should validate_presence_of :uid
    should_validate_uniqueness_of :uid, :scoped_to => :council_id
    should have_db_column :council_id
    should have_db_column :applicant_name
    should have_db_column :applicant_address
    should have_db_column :address
    should have_db_column :postcode
    should have_db_column :description
    should have_db_column :url
    should have_db_column :comment_url
    should have_db_column :uid
    should have_db_column :retrieved_at
    should have_db_column :start_date
    should have_db_column :status
    should have_db_column :application_type
    should have_db_column :bitwise_flag

    should belong_to :council

    should "serialize other attributes" do
      assert_equal({:foo => 'bar'}, Factory(:planning_application, :other_attributes => {:foo => 'bar'}).reload.other_attributes)
    end
    
    should "set bitwise_flag to be zero if not set on creation" do
      assert_equal 0, Factory(:planning_application).bitwise_flag
      assert_equal 0, Factory(:planning_application, :bitwise_flag => nil).bitwise_flag
    end

    should "act as mappable" do
      assert PlanningApplication.respond_to?(:find_closest)
    end

    context "stale named scope" do
      setup do
        @no_details_application = Factory(:planning_application) #retrieved_at is nil
        @stale_application = Factory(:planning_application, :retrieved_at => 2.months.ago) 
        @too_old_to_be_stale_application = Factory(:planning_application, :retrieved_at => 4.months.ago)
        @stale_applications = PlanningApplication.stale
      end

      should "include applications where retrieved_at is nil" do
        assert @stale_applications.include?(@no_details_application)
      end
      
      should "include applications where retrieved at is more than a week ago" do
        assert @stale_applications.include?(@stale_application)
      end
      
      should "not include applications too old to be stale" do
        assert !@stale_applications.include?(@too_old_to_be_stale_application)
      end
    end
    
    context "recent named scope" do
      setup do
        @no_date_started_application = Factory(:planning_application) #retrieved_at is nil
        @old_date_started_application = Factory(:planning_application, :start_date => 3.weeks.ago) 
        @recent_date_started_application = Factory(:planning_application, :start_date => 2.days.ago)
        4.times { |i| Factory(:planning_application, :start_date => (i+3).days.ago) }
        @recent_applications = PlanningApplication.recent
      end

      should "include only applications where date_started is set and less than 2 weeks ago" do
        assert_equal 5, @recent_applications.size
        assert !@recent_applications.include?(@no_date_started_application)
        assert !@recent_applications.include?(@old_date_started_application)
        assert @recent_applications.include?(@recent_date_started_application)
      end
      
      should "order by date_started with most recent first" do
        assert_equal @recent_date_started_application, @recent_applications.first
      end
      
      should "limit to 5 results by default" do
        Factory(:planning_application, :start_date => 1.days.ago)
        recent_applications = PlanningApplication.recent
        assert_equal 5, recent_applications.size
      end
      
    end
    
    context "stale with_clear_bitwise_flag scope" do
      setup do
        @clear_bitwise_flag = Factory(:planning_application, :bitwise_flag => 0)
        @set_bitwise_flag = Factory(:planning_application, :bitwise_flag => 3) 
        @clear_bitwise_flag_for_given_number = Factory(:planning_application, :bitwise_flag => 5)
        @with_clear_bitwise_flags = PlanningApplication.with_clear_bitwise_flag(2)
      end

      should "include applications where bitwise_flag is clear for all given numbers" do
        assert @with_clear_bitwise_flags.include?(@clear_bitwise_flag)
      end
      
      should "include applications where bitwise_flag is clear for particular given number" do
        assert @with_clear_bitwise_flags.include?(@clear_bitwise_flag_for_given_number)
      end
      
      should "not include applications where bitwise_flag is set for particular given number" do
        assert !@with_clear_bitwise_flags.include?(@set_bitwise_flag)
      end
    end
    
    context "with_data named scope" do
      setup do
        @no_details_application = Factory(:planning_application) #retrieved_at is nil
        @with_details_application = Factory(:planning_application, :retrieved_at => 2.months.ago) 
        @with_details_applications = PlanningApplication.with_details
      end

      should "include applications where retrieved_at is not nil" do
        assert @with_details_applications.include?(@with_details_application)
      end
      
      should "not include applications where retrieved at is nil" do
        assert !@with_details_applications.include?(@no_details_application)
      end
      
      # should "not include applications too old to be stale" do
      #   assert !@with_details_applications.include?(@too_old_to_be_stale_application)
      # end
    end
    
    context "should overwrite find_all_existing and" do
      should "return empty array" do
        assert_equal [], PlanningApplication.find_all_existing(:organisation => @planning_application.council)
      end
    end
    
    context "should overwrite record_not_found_behvaiour" do
      should "instantiate new instance from params" do
        record_not_found_object = PlanningApplication.send(:record_not_found_behaviour, 'uid' => 'AB12345', :council => @planning_application.council)
        assert_equal PlanningApplication.new('uid' => "AB12345", :council => @planning_application.council).attributes, record_not_found_object.attributes
        assert record_not_found_object.new_record?
      end
      
      should "assign new attributes to existing record if it exists" do
        record_not_found_object = PlanningApplication.send(:record_not_found_behaviour, 'description' => 'Some new description', 'uid' => @planning_application.uid, :council => @planning_application.council)
        assert_equal 'Some new description', record_not_found_object.description
        assert !record_not_found_object.new_record?
        assert_equal @planning_application.id, record_not_found_object.id
      end
    end
    
    context "when returning queue" do
      should "return :planning_applications" do
        assert_equal :planning_applications, PlanningApplication.instance_variable_get(:@queue)
      end
    end
  end

  
  context "an instance of the PlanningApplication class" do
    setup do
      @planning_application = Factory(:planning_application)
    end
    
    context "when returning title" do
      should "use uid reference" do
        assert_equal "Planning Application AB123/456", PlanningApplication.new(:uid => 'AB123/456').title
      end
      
      should "use address if given" do
        assert_match /32 Acacia Avenue/, PlanningApplication.new(:address => '32 Acacia Avenue, Footown FOO1 3BA').title
      end
      
      should "use council reference and address if given" do
        application =  PlanningApplication.new(:uid => 'AB123/456', :address => '32 Acacia Avenue, Footown FOO1 3BA')
        assert_match /32 Acacia Avenue/, application.title
        assert_match /AB123\/456/, application.title
      end
    end
    
    should "alias uid attribute as council_reference" do
      pa = Factory(:planning_application)
      assert_equal pa.uid, pa.council_reference
      pa.council_reference = 'FOO1234'
      assert_equal 'FOO1234', pa.uid
    end
    
    should "return 13 for google_map_magnfication" do
      assert_equal 13, Factory(:planning_application).google_map_magnification
    end
    
    context "on save" do
      setup do
        Resque.stubs(:enqueue)
      end

      should "get inferred_lat_lng" do
        @planning_application.expects(:inferred_lat_lng)
        @planning_application.save!
      end

      should "update lat & lng with inferred_lat_lng" do
        @planning_application.stubs(:inferred_lat_lng).returns([12.1,23.2])
        @planning_application.save!
        assert_equal 12.1, @planning_application.lat
        assert_equal 23.2, @planning_application.lng
      end
      
      should "set lat, lng to nil if inferred_lat_lng is nil" do
        @planning_application.update_attributes(:lat => 22.2, :lng => 33.3)
        @planning_application.stubs(:inferred_lat_lng) # => nil
        @planning_application.save!
        assert_nil @planning_application.lat
        assert_nil @planning_application.lng
      end
      
      should "set not lat, lng to nil when inferred_lat_lng is nil if lat,lng has just changed" do
        @planning_application.lat = 22.2
        @planning_application.lng = 33.3
        @planning_application.stubs(:inferred_lat_lng) # => nil
        @planning_application.save!
        assert_equal 22.2, @planning_application.lat
        assert_equal 33.3, @planning_application.lng
      end
      
      should "not queue for emailing" do
        @planning_application.expects(:queue_for_sending_alerts).never
        @planning_application.save!
      end
      
      context "and planning_application has lat & long" do
        setup do
          @planning_application.lat = 22.2
          @planning_application.lng = 33.3
        end
        
        context "and didn't previously have lat long" do

          should "queue for emailing" do
            @planning_application.changes
            @planning_application.expects(:queue_for_sending_alerts)
            @planning_application.save!
          end
        end
        
        context "and did previously have lat long" do
          setup do
            @planning_application.save!
          end

          should "not queue for sending alerts" do
            @planning_application.changes
            @planning_application.save!
            @planning_application.changes
            @planning_application.expects(:queue_for_sending_alerts).never
            @planning_application.save!
          end
        end
        
      end
      
      should "set the start_date to be earliest of date_received and date_validated" do
        @planning_application.other_attributes = {:date_received => '2010-11-22', :date_validated => '2010-12-03'}
        @planning_application.save!
        assert_equal '2010-11-22'.to_date.to_s, @planning_application.start_date.to_s
        @planning_application.other_attributes = {:date_validated => '2010-11-22', :date_received => '2010-12-03'}
        @planning_application.save!
        assert_equal '2010-11-22'.to_date.to_s, @planning_application.start_date.to_s
      end
      
      should "not set the start_date if date_received and date_validated blank" do
        @planning_application.other_attributes = {:date_received => '', :date_validated => ''}
        @planning_application.save!
        assert_nil @planning_application.reload.start_date
      end
      
      should "not override explicitly set start date" do
        @planning_application.start_date = '2010-12-03'
        @planning_application.other_attributes = {:date_validated => '', :date_received => ''}
        @planning_application.save!
        assert_equal '2010-12-03'.to_date.to_s, @planning_application.start_date.to_s
      end
      
      should "not set the start_date if date_received and date_validated not valid dates" do
        @planning_application.other_attributes = {:date_received => '00/03/2012', :date_validated => 'foo'}
        @planning_application.save!
        assert_nil @planning_application.start_date
      end
      
      should "convert US dates to UK format start_date if date_received and date_validated not valid dates" do
        @planning_application.other_attributes = {:date_received => '20/03/2012', :date_validated => 'foo'}
        @planning_application.save!
        assert_equal '2012-03-20', @planning_application.start_date.to_s
      end
      
      should "convert text dates to date" do
        @planning_application.other_attributes = {:date_received => 'Thu 08 Mar 2012', :date_validated => 'foo'}
        @planning_application.save!
        assert_equal '2012-03-08', @planning_application.start_date.to_s
      end
      
      should "use date_received or date_validated if start_date explicitly set to blank" do
        # regression test
        @planning_application.start_date = ''
        @planning_application.other_attributes = {:date_received => '2010-11-22', :date_validated => '2010-12-03'}
        @planning_application.save!
        assert_equal '2010-11-22'.to_date.to_s, @planning_application.start_date.to_s
      end
    end
    
    context "when assigning address" do
      setup do
        @dummy_address = '32 Acacia Avenue, Footown FO1 3BA'
      end
      
      should "not raise exception when address is blank" do
        assert_nothing_raised(Exception) { Factory.build(:planning_application, :address => nil) }
        assert_nothing_raised(Exception) { Factory.build(:planning_application, :address => '') }
      end

      should "set address attribute" do
        assert_equal @dummy_address, Factory(:planning_application, :address => @dummy_address)[:address]
      end
      
      should "remove extra spaces" do
        assert_equal @dummy_address, Factory(:planning_application, :address => "\n 32   Acacia Avenue,  Footown FO1 3BA  \n")[:address]
      end
      
      should "normalise line breaks" do
        assert_equal "32 Acacia Avenue\nFootown\nFOO1 3BA", Factory(:planning_application, :address => "32   Acacia Avenue\rFootown\rFOO1 3BA")[:address]
      end
      
      should "set postcode attribute" do
        assert_equal 'FO1 3BA', Factory(:planning_application, :address => @dummy_address)[:postcode]
      end
      
      context "and postcode already set" do
        setup do
          @planning_application = Factory(:planning_application, :address => @dummy_address)
          @new_address = '43 Cherry Road, Bartown BA2 5AB'
        end
        
        should "not set postcode if postcode has already changed" do
          @planning_application.postcode = 'AB1 3CD'
          @planning_application.address = @new_address
          assert_equal 'AB1 3CD', @planning_application.postcode
        end
        
        should "set postcode if postcode has not already changed" do
          @planning_application.address = @new_address
          assert_equal 'BA2 5AB', @planning_application.postcode
        end
      end
    end
    
    context "when setting bitwise flag" do

      should "do nothing if if nil given" do
        @planning_application[:bitwise_flag] = 0b0101
        @planning_application.bitwise_flag = nil
        assert_equal 0b0101, @planning_application.bitwise_flag
      end
      
      should "perform bitwise OR from given number" do
        @planning_application[:bitwise_flag] = 0b001
        @planning_application.bitwise_flag = 0b011
        assert_equal 0b011, @planning_application.bitwise_flag
      end
      
      should "set to given number if currently nil" do
        @planning_application.bitwise_flag = 0b0010
        assert_equal 0b0010, @planning_application.bitwise_flag
      end
      
      should "set to zero if full count" do
        @planning_application[:bitwise_flag] = 0b101
        @planning_application.bitwise_flag = 0b010
        assert_equal 0, @planning_application.bitwise_flag
      end
    end
    
    context "when returning inferred lat long" do
      setup do
        @postcode = Factory(:postcode, :code => 'AB12CD')
      end
      
      should "return lat_long for postcode matching normalised postcode" do
        @planning_application.postcode = 'AB1 2CD'
        inferred_lat_lng = @planning_application.inferred_lat_lng
        assert_in_delta @postcode.lat, inferred_lat_lng.first, 0.01
        assert_in_delta @postcode.lng, inferred_lat_lng.last, 0.01
      end

      should "return nil if postcode is blank" do
        assert_nil @planning_application.inferred_lat_lng
      end
      
      should "return nil if no such postcode" do
        @planning_application.postcode = 'CD2 1AB'
        assert_nil @planning_application.inferred_lat_lng
      end
    end

    context "when returning date_received" do
      
      should "return nil if no other attributes" do
        assert_nil @planning_application.date_received
      end

      should "return nil if no date_received in other attributes" do
        @planning_application.other_attributes = {:foo => 'bar'}
        assert_nil @planning_application.date_received
      end

      should "return normalised date_received if date_received in other attributes" do
        @planning_application.other_attributes = {:foo => 'bar', :date_received => '2012-03-22'}
        assert_equal '2012-03-22', @planning_application.date_received
        @planning_application.other_attributes = {:foo => 'bar', :date_received => "Thu 08 Mar 2012"}
        assert_equal '2012-03-08', @planning_application.date_received
        @planning_application.other_attributes = {:foo => 'bar', :date_received => "foo bar"}
        assert_nil @planning_application.date_received
      end

    end

    context "when returning date_validated" do
      
      should "return nil if no other attributes" do
        assert_nil @planning_application.date_validated
      end

      should "return nil if no date_received in other attributes" do
        @planning_application.other_attributes = {:foo => 'bar'}
        assert_nil @planning_application.date_validated
      end

      should "return normalised date_received if date_received in other attributes" do
        @planning_application.other_attributes = {:foo => 'bar', :date_validated => '2012-03-22'}
        assert_equal '2012-03-22', @planning_application.date_validated
        @planning_application.other_attributes = {:foo => 'bar', :date_validated => "Thu 08 Mar 2012"}
        assert_equal '2012-03-08', @planning_application.date_validated
        @planning_application.other_attributes = {:foo => 'bar', :date_validated => "foo bar"}
        assert_nil @planning_application.date_validated
      end

    end

    context "when returning normalised_application_status" do
      
      should "return nil if status attribute blank" do
        assert_nil PlanningApplication.new.normalised_application_status
        assert_nil PlanningApplication.new(:status => '').normalised_application_status
      end
      
      should "normalise status to be one of standard types" do
        raw_and_normalised_statuses = { 'Application PENDING  ' => 'pending',
                                        'Decision PENDING  ' => 'pending',
                                        'PENDING  CONSIDERATION ' => 'pending',
                                        'APPLICATION  approved ' => 'approved',
                                        'Application Withdrawn by Applicant' => 'withdrawn',
                                        'Application Permitted' => 'approved',
                                        'rejected '  => 'refused',
                                        'Withdrawn by Applicant' => 'withdrawn',
                                        'Invalid application - Unacceptable-invalid' => 'invalid',
                                        'Refusal of planning permission - Decided' => 'refused'
          }
        raw_and_normalised_statuses.each do |raw_status, expected_normalised_status|
          assert_equal expected_normalised_status, PlanningApplication.new(:status => raw_status).normalised_application_status, "'#{raw_status}' failed to be normalised to '#{expected_normalised_status}'"
        end
      end
    end
    
    context "when assigning start_date" do

      should "treat as UK formatted date" do
        @planning_application.start_date = '3/5/2001'
        assert_equal '2001-05-03', @planning_application.start_date.to_s
      end
    end
    
    context "when queueing for sending alerts" do
      should "queue as Resque job" do
        Resque.expects(:enqueue).with(PlanningApplication, @planning_application.id)
        @planning_application.queue_for_sending_alerts
      end
    end
    
    context "when converting planning_application to_xml" do
      setup do
        @planning_application.update_attributes(:other_attributes => {:agent_name => 'Fred Flintstone'})
        @xml_representation = Nokogiri.XML(@planning_application.to_xml)
      end
      
      should "include openlylocal_url" do
        assert @xml_representation.at('openlylocal-url')
      end
      
      should "exclude bitwise_flag" do
        assert_nil @xml_representation.at('bitwise-flag')
      end
      
      should "exclude applicant name" do
        assert_nil @xml_representation.at('applicant-name')
      end
      
      should "exclude other_attributes" do
        assert_nil @xml_representation.at('other-attributes')
      end
      
      should "exclude applicant address" do
        assert_nil @xml_representation.at('applicant-address')
      end
      
      should "exclude council" do
        assert_nil @xml_representation.at('council')
      end
    end

    context "when converting planning_application to_detailed_xml" do
      setup do
        @planning_application.update_attributes(:other_attributes => {:agent_name => 'Fred Flintstone'})
        @xml_representation = Nokogiri.XML(@planning_application.to_detailed_xml)
      end
      
      should "include openlylocal_url" do
        assert @xml_representation.at('openlylocal-url')
      end
      
      should "exclude bitwise_flag" do
        assert_nil @xml_representation.at('bitwise-flag')
      end
      
      should "exclude applicant name" do
        assert_nil @xml_representation.at('applicant-name')
      end
      
      should "exclude applicant address" do
        assert_nil @xml_representation.at('applicant-address')
      end
      
      should "include council" do
        assert_equal @planning_application.council_id.to_s, @xml_representation.at('council>id').inner_text
      end
      
      should "include other attributes" do
        assert_equal 'Fred Flintstone', @xml_representation.at('other-attributes>agent-name').content
      end
    end

    # context "when returning matching subscribers" do
    #   setup do
    #     
    #   end
    # 
    #   should "find all subscribers where planning application lat long is within bounding box" do
    #     
    #   end
    #   
    #   context "and lat long is nil" do
    #     should "not find subscribers" do
    #       
    #     end
    #   end
    # end
    # 
    context "when sending alerts" do
      setup do
        @alert_subscriber = Factory(:alert_subscriber)
        @planning_application.stubs(:matching_subscribers).returns([@alert_subscriber])
      end
    
      should "find all matching subscribers" do
        @planning_application.expects(:matching_subscribers).returns([])
        @planning_application.send_alerts
      end
      
      should "send planning alert to matching subscribers with planning application" do
        @alert_subscriber.expects(:send_planning_alert).with(@planning_application)
        @planning_application.send_alerts
      end
    end
  end
  
end
