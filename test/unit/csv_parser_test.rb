require File.expand_path('../../test_helper', __FILE__)

class CsvParserTest < ActiveSupport::TestCase
  def setup
    @parser = Factory(:csv_parser)
  end
  
  context "The CsvParser class" do
    should 'be a subclass of Parser' do
      assert_equal Parser, CsvParser.superclass
    end
    
    should have_db_column :attribute_mapping
    should have_db_column :skip_rows
    
    should "serialize attribute_mapping" do
      expected_attribs = {:value => "amount", 
                          :department_name => 'directorate', 
                          :supplier_name => 'supplier_name', 
                          :uid => 'transactionid',
                          :date => 'updated' }
      assert_equal(expected_attribs, Parser.find(@parser.id).attribute_mapping)
    end

  end

  context "a CsvParser instance" do
    setup do
      @csv_rawdata = dummy_csv_data('supplier_payments')
    end

    context "with attribute_mapping has attribute_mapping_object which" do
      setup do
        @attribute_mapping_object = @parser.attribute_mapping_object
      end
      
      should "be an Array" do
        assert_kind_of Array, @attribute_mapping_object
      end
      
      should "be same size as attribute_mapping" do
        assert_equal @parser.attribute_mapping.keys.size, @attribute_mapping_object.size
      end
      
      context "has elements which" do
        setup do
          @first_attrib = @attribute_mapping_object.first
        end

        should "are Structs" do
          assert_kind_of MappingObject, @first_attrib
        end
        
        should "make attribute_mapping_key accessible as attrib_name" do
          assert_equal "date", @first_attrib.attrib_name
        end

        should "make attribute_mapping_value accessible as column_name" do
          assert_equal "updated", @first_attrib.column_name
        end
      end
      
      context "when attribute_mapping is blank" do
        setup do
          @empty_attribute_mapping_object = CsvParser.new.attribute_mapping_object
        end

        should "be an Array" do
          assert_kind_of Array, @empty_attribute_mapping_object
        end
        
        context "and which" do
          should "should have an empty MappingObject as only element" do
            assert_kind_of MappingObject, @empty_attribute_mapping_object.first
          end
        end
      end
      
      context "when given attribute_mapping info from form params" do

        should "convert to attribute_mapping hash" do
          @parser.attribute_mapping_object = [{ "attrib_name" => "title",
                                               "column_name" => "a title"},
                                             { "attrib_name" => "description",
                                               "column_name" => "a longer description"}]
          assert_equal({ :title => "a_title", :description => "a_longer_description" }, @parser.attribute_mapping)
        end

        should "normalise column names" do
          @parser.attribute_mapping_object = [{ "attrib_name" => "title",
                                               "column_name" => "A  Title "},
                                             { "attrib_name" => "description",
                                               "column_name" => "a - LONGER ** (description)  "}]
          assert_equal({ :title => "a_title", :description => "a_longer_description" }, @parser.attribute_mapping)
        end

        should "set attribute_parser to empty hash if no form_params" do
          @parser.attribute_mapping_object = []
          assert_equal({}, @parser.attribute_mapping)
        end
      end

    end
    
    
    context "when processing" do
      
      setup do
        @dummy_org = stub()
        @dummy_scraper = stub_everything(:council => @dummy_org, :url => "http://foo.gov.uk/bar.csv")
      end
	        
	    should "return self when scraper is set" do
        assert_equal @parser, @parser.process(@csv_rawdata,@dummy_scraper)
      end
    
      should "save given scraper in instance variable" do
        scraper = stub
        assert_equal scraper, @parser.process(@csv_rawdata, scraper).instance_variable_get(:@current_scraper)
      end
      
      should "return self when scraper is not set" do
        assert_equal @parser, @parser.process(@csv_rawdata)
      end
      
      should 'store results as results' do
        assert_nil @parser.results
        @parser.process(@csv_rawdata)
        assert_not_nil @parser.results
      end
      
      context "when processing with dry run" do

        setup do
          @processed_data = @parser.process(@csv_rawdata, @dummy_scraper).results
        end

        should 'return only first ten results' do
          assert_equal 10, @processed_data.size
        end

        should "map row headings to attributes" do
          assert_equal 'Resources', @processed_data.first[:department_name]
          assert_equal '1,000.00', @processed_data.first[:value]
        end

        should "normalise row headings to attributes by downcasing and removing extra spaces" do
          assert_equal 'Idox Software Limited', @processed_data.first[:supplier_name]
        end
        
        should "in general discard unmapped attributes" do
          assert_nil @processed_data.first[:type]
        end
        
        context "and result_model has other_attributes attribute" do
          setup do
            @parser.result_model = 'TestScrapedModelWithOtherAttribs'
            @processed_data = @parser.process(@csv_rawdata, @dummy_scraper).results
          end

          should "include unmapped attributes" do
            assert_equal 'Capital', @processed_data.first[:type]
          end
          
          should "heavily normalise unmapped csv_headings" do
            assert_equal 'foo', @processed_data.first[:an_unmapped_column]
          end
        end

      end
      
      context "when processing with parser with skip_rows set" do
        setup do
          dummy_data = dummy_csv_data(:file_with_extra_lines_at_top)
          @parser.skip_rows = 2
          @processed_data = @parser.process(dummy_data, @dummy_scraper).results
        end

        should "skip given rows" do
          assert_equal 'Resources', @processed_data.first[:department_name]
          assert_equal 'Idox Software Limited', @processed_data.first[:supplier_name]
        end
        
        should 'return csv line number of file as csv_line_no' do
          assert_equal 4, @processed_data.first[:csv_line_number]
        end

      end
      
      context "when processing with parser rows that includes Windows pound sign" do
        setup do
          dummy_data = dummy_csv_data(:windows_file_with_pound_signs_in_heading)
          @parser.attribute_mapping = {:supplier_name => 'supplier name', :value => 'amount_£_excl_vat'}
          @processed_data = @parser.process(dummy_data, @dummy_scraper).results
        end

        should "convert to UTF-8 to allow extraction of value" do
          assert_equal "11889.82", @processed_data.first[:value]
        end
        
      end
      
      context 'and results' do
        setup do
          @processed_data = @parser.process(@csv_rawdata, @dummy_scraper, :save_results => true).results
        end
        
        should 'be an array of hashes' do
          assert_kind_of Array, @processed_data
          assert_kind_of Hash, @processed_data.first
        end

        should 'return results for every possible line' do
          assert_equal 19, @processed_data.size
        end

        should "map row headings to attributes" do
          assert_equal 'Resources', @processed_data.first[:department_name]
          assert_equal 'Idox Software Limited', @processed_data.first[:supplier_name]
        end
        
        should "map given values for attributes when attribute has is value_for name" do
          @parser.attribute_mapping = { :department_name => 'Directorate', :supplier_name => 'Supplier Name', :uid => 'TransactionID', :value_for_foo => 'bar' }
          
          assert_equal 'bar', @parser.process(@csv_rawdata, @dummy_scraper).results.first[:foo]
        end

        should "ignore blank rows" do
          assert !@processed_data.any?{ |r| r.all?{ |k,v| v.blank?  }  }
          assert_equal 'Zychem Ltd', @processed_data.last[:supplier_name]
        end
        
        should 'return csv line number as csv_line_no' do
          assert_equal 21, @processed_data.last[:csv_line_number]
        end

        should 'return scraper url as source_url' do
          assert_equal "http://foo.gov.uk/bar.csv", @processed_data.last[:source_url]
        end

        should 'override scraper url if value provided for source_url' do
          @parser.attribute_mapping = { :department_name => 'Directorate', :supplier_name => 'Supplier Name', :uid => 'TransactionID', :value_for_source_url => 'http://bar.gov.uk/baz.csv' }
          assert_equal 'http://bar.gov.uk/baz.csv', @parser.process(@csv_rawdata, @dummy_scraper).results.first[:source_url]
        end

      end
      
      context "and problems occur when parsing" do
      
        should "not raise exception" do
          assert_nothing_raised() { @parser.process("foo,\"bar,\"baz") }
          assert_nothing_raised() { @parser.process(nil) }
        end
        
        should "return self" do
          assert_equal @parser, @parser.process('foo')
        end
        
        should "store errors in parser" do
          assert errors = @parser.process(nil).errors[:base]
          assert_match /Exception raised parsing csv/i, errors
        end
      end
    end
    
  end
end