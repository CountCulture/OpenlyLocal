require 'test_helper'

class CsvParserTest < ActiveSupport::TestCase
  def setup
    @parser = Factory(:csv_parser)
  end
  
  context "The CsvParser class" do
    should 'be a subclass of Parser' do
      assert_equal Parser, CsvParser.superclass
    end
    
    should have_db_column :attribute_mapping
    
    should "serialize attribute_mapping" do
      assert_equal({ :directorate => 'Directorate', :supplier_name => 'Supplier Name', :transaction_id => 'TransactionID', :value_for_foo => 'bar' }, @parser.reload.attribute_mapping)
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
          assert_kind_of Struct, @first_attrib
        end
        
        should "make attribute_mapping_key accessible as attrib_name" do
          assert_equal "directorate", @first_attrib.attrib_name
        end

        should "make attribute_mapping_value accessible as column_name" do
          assert_equal "Directorate", @first_attrib.column_name
        end
      end
      
      context "when attribute_mapping is blank" do
        setup do
          @empty_attribute_mapping_object = CsvParser.new.attribute_mapping_object
        end

        should "be an Array" do
          assert_kind_of Array, @empty_attribute_mapping_object
        end

        should "with one element" do
          assert_equal 1, @empty_attribute_mapping_object.size
        end
        
        should "is an empty Struct" do
          assert_equal CsvParser::MappingObject.new, @empty_attribute_mapping_object.first
        end
      end
      
      context "when given attribute_mapping info from form params" do

        should "convert to attribute_mapping hash" do
          @parser.attribute_mapping_object = [{ "attrib_name" => "title",
                                               "column_name" => "A title"},
                                             { "attrib_name" => "description",
                                               "column_name" => "A longer description"}]
          assert_equal({ :title => "A title", :description => "A longer description" }, @parser.attribute_mapping)
        end

        should "set attribute_parser to empty hash if no form_params" do
          @parser.attribute_mapping_object = []
          assert_equal({}, @parser.attribute_mapping)
        end
      end

    end
    
    
    context "when processing" do
      
      should "return self" do
        assert_equal @parser, @parser.process(@csv_rawdata)
      end
      
      should 'store results as results' do
        assert_nil @parser.results
        @parser.process(@csv_rawdata)
        assert_not_nil @parser.results
      end
      
      context 'and results' do
        setup do
          @processed_data = @parser.process(@csv_rawdata).results
        end
        
        should 'be an array of hashes' do
          assert_kind_of Array, @processed_data
          assert_kind_of Hash, @processed_data.first
        end

        should "map row headings to attributes" do
          assert_equal 'Resources', @processed_data.first[:directorate]
          assert_equal 'Idox Software Limited', @processed_data.first[:supplier_name]
        end
        
        should "map given values for attributes when attribute has is value_for name" do
          assert_equal 'bar', @processed_data.first[:foo]
        end

        should "ignore blank rows" do
          assert !@processed_data.any?{ |r| r.all?{ |k,v| v.blank?  }  }
          assert_equal 'Zychem Ltd', @processed_data.last[:supplier_name]
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
        
        # should "separate consecutive points in parsing code when storing errors in parser" do
        #   # This is because of bug in Rails when displaying errors with consecutive points
        #   errors = @problem_parser.process('foo').errors[:base]
        #   assert_match /Problem .+parsing code.+foobar \+ \(1\. \.2\)/m, errors
        # end
        # 
        # should "separate consecutive points in item to be parsed when storing errors in parser" do
        #   # This is because of bug in Rails when displaying errors with consecutive points
        #   errors = @problem_parser.process(@dummy_hpricot_for_attrib_prob).errors[:base]
        #   assert_match /Problem .+parsing.+on following.+some string\. \. \. here/m, errors
        # end
      end
    end
    
    context "when processing with dry run" do

      should "map row headings to attributes" do
        
      end
    end
  end
end