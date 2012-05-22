require File.expand_path('../../test_helper', __FILE__)

class DocumentTest < ActiveSupport::TestCase
  subject { @document }
  
  def setup
    @committee = Factory(:committee)
    @council = @committee.council
    @doc_owner = Factory(:meeting, :council => @committee.council, :committee => @committee)
    @document = Factory(:document, :document_owner => @doc_owner)
  end
  
  context "The Document class" do  
    should validate_presence_of :url
    should validate_presence_of :document_owner_id
    should validate_presence_of :document_owner_type
    should belong_to :document_owner
    should have_db_column :raw_body
    should have_db_column :precis
    
    should "validate presence of body" do
      # we have to test this explicitly as shoulda macro gives other 
      # attributes (inc raw_body) values, which means body is given 
      # one too via before validation callback
      d = Document.new
      d.valid?
      assert_equal "can't be blank", d.errors[:body]
    end
    
    should "validate uniqueness of document_type scoped to document_type" do
      # can't do this with macro as it doesn't work when document_type is nil, which it can be
      @document.update_attribute(:document_type, "Minutes")
      d = Document.new(:url => @document.url, :document_type => "Minutes")
      d.valid?
      assert_equal "has already been taken", d.errors[:url]
      d.document_type = "foo"
      d.valid?
      assert_nil d.errors[:url]
    end
    
    should "include ScraperModel mixin" do
      assert Document.respond_to?(:find_all_existing)
    end
    
    context 'when saving' do
      should 'calculate precis' do
        unsaved_doc = Factory.build(:document, :document_owner => @doc_owner)
        DocumentUtilities.expects(:precis).with(unsaved_doc.raw_body).returns('Hello World')
        unsaved_doc.save!
      end
      
      should 'save precis' do
        unsaved_doc = Factory.build(:document, :document_owner => @doc_owner)
        DocumentUtilities.stubs(:precis).returns('Hello World')
        unsaved_doc.save!
        assert_equal 'Hello World', unsaved_doc.reload.precis
      end
    end
    
    context "when returning quick_count" do
      setup do
        10.times {Factory(:document, :document_owner => @doc_owner)}
      end

      should "return count of documents" do
        assert_equal Document.count, Document.quick_count
      end
    end
    
  end
  
  context "A Document instance" do
    
    context "in general" do
      
      should "return document owner's council as council" do
        assert_equal @council, @document.council
      end
      
      should "return title attribute if set" do
        @document.title = "new title"
        assert_equal "new title", @document.title
      end
      
      should "return document type, document owner extended title as title" do
        @document.stubs(:document_type).returns("FooDocument")
        assert_equal "FooDocument for #{@doc_owner.extended_title}", @document.title
      end
      
      should "return document type, document owner extended title as extended title" do
        @document.stubs(:document_type).returns("FooDocument")
        assert_equal "FooDocument for #{@doc_owner.extended_title}", @document.extended_title
      end
      
      should "return title attribute as extended title if set" do
        @document.title = "new title"
        assert_equal "new title", @document.extended_title
      end
      
      should "return 'Document' as document_type if not set" do
        assert_equal "Document", @document.document_type
      end
      
      should "return document_type if set" do
        @document.document_type = "Minutes"
        assert_equal "Minutes", @document.document_type
      end
      
      context "before saving" do

        should "should sanitize raw_body" do
          @document.expects(:sanitize_body)
          @document.save!
        end
        
      end

    end
    
    context "when converting document to_xml" do
      should "include id" do
        assert_match %r(<id), @document.to_xml
      end
      
      should "include openlylocal_url" do
        assert_match %r(<openlylocal-url), @document.to_xml
      end
      
      should "include council url" do
        assert_match %r(<url), @document.to_xml
      end
      
      should "include title" do
        assert_match %r(<title), @document.to_xml
      end
      
      should "include status" do
        assert_match %r(<status), @document.to_xml
      end
    end
    
  end
end
