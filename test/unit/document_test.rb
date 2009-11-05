require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  subject { @document }
  
  def setup
    @committee = Factory(:committee)
    @council = @committee.council
    @doc_owner = Factory(:meeting, :council => @committee.council, :committee => @committee)
    @document = Factory(:document, :document_owner => @doc_owner)
  end
  context "The Document class" do
    
    should_validate_presence_of :url
    should_validate_presence_of :document_owner_id
    should_validate_presence_of :document_owner_type
    should_belong_to :document_owner
    should_have_db_column :raw_body
    
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
      assert Document.respond_to?(:find_existing)
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

      context "when sanitizing body text" do
        setup do
          raw_text = "some <font='Helvetica'>stylized text</font> with <a href='councillor22'>relative link</a> and an <a href='http://external.com/dummy'>absolute link</a> and a <a href='mailto:foo@test.com'>mailto link</a>. Also <script> something dodgy</script> here and <img src='http://council.gov.uk/image' /> image and some <!--[if !supportLists]-->cruft<!--[endif]--> <![if !supportLists]>here<![endif]>"
          @document.attributes = {:url => "http://www.council.gov.uk/document/some_page.htm?q=something", :raw_body => raw_text}
          @document.send(:sanitize_body)
        end

        should "convert relative urls to absolute ones based on url" do
          assert_match /with <a href="http:\/\/www\.council\.gov\.uk\/document\/councillor22/, @document.body
        end

        should "not change urls of absolute links" do
          assert_match /an <a href=\"http:\/\/external\.com\/dummy\"/, @document.body
        end

        should "not change urls of mailto links" do
          assert_match /a <a href=\"mailto:foo@test\.com/, @document.body
        end

        should "add external class to all links" do
          assert_match /councillor22\" class=\"external/, @document.body
          assert_match /dummy\" class=\"external/, @document.body
        end

        should "remove images" do
          assert_match /and  image/, @document.body
        end
        
        should "remove comments" do
          assert_match /some cruft/, @document.body
          assert_match /cruft here/, @document.body
        end
      end
      
      context "when returning precis" do
        setup do
          raw_text = "some <font='Helvetica'>stylized text</font> with <a href='councillor22'>relative link</a> and an <a href='http://external.com/dummy'>absolute link</a>.\n\r\n\n\n   \r\n\tAlso <script> something dodgy</script> here \r\nand <img src='http://council.gov.uk/image' /> image"
          @document.attributes = {:url => "http://www.council.gov.uk/document/some_page.htm?q=something", :raw_body => raw_text*20}
          @document.save!
        end

        should "remove all tags" do
          assert_no_match %r(<.+>), @document.precis
        end
        
        should "not remove text in tags" do
          assert_match %r(some stylized text with relative link), @document.precis
        end
        
        should "trim multiple line spaces to single space" do
          assert_match %r(absolute link.\nAlso), @document.precis
        end
        
        should "trim to 500 chars in length" do
          assert_equal 500, @document.precis.length
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
    end
    
    # context "when setting body" do
    #   setup do
    #     @document = Document.new
    #   end
    # 
    #   should "store raw text in raw_body" do
    #     assert_equal "raw <font='Helvetica'>text</font>", Document.new(:body => "raw <font='Helvetica'>text</font>").raw_body
    #   end
    #   
    #   should "sanitize raw text" do
    #     @document.expects(:sanitize_body).with("raw <font='Helvetica'>text</font>")
    #     @document.body = "raw <font='Helvetica'>text</font>"
    #   end
    #   
    #   should "store sanitized text in body" do
    #     @document.stubs(:sanitize_body).returns("sanitized text")
    #     @document.body = "raw text"
    #     assert_equal "sanitized text", @document.body
    #   end
    #   
    #   should "not raise exception when setting body to nil" do
    #     assert_nothing_raised(Exception) { @document.body = nil }
    #   end
    # end
    
    # context "when sanitizing body text" do
    #   setup do
    #     @raw_text = "some <font='Helvetica'>stylized text</font> with <a href='councillor22'>relative link</a> and an <a href='http://external.com/dummy'>absolute link</a>. Also <script> something dodgy</script> here"
    #     @document = Document.new(:url => "http://www.council.gov.uk/document/some_page.htm?q=something")
    #   end
    #   
    #   should "convert relative urls to absolute ones based on url" do
    #     assert_match /with <a href="http:\/\/www\.council\.gov\.uk\/document\/councillor22/, @document.send(:sanitize_body, @raw_text)
    #   end
    #   
    #   should "not change urls of absolute links" do
    #     assert_match /an <a href=\"http:\/\/external\.com\/dummy\"/, @document.send(:sanitize_body, @raw_text)
    #   end
    #   
    #   should "add external class to all links" do
    #     assert_match /councillor22\" class=\"external/, @document.send(:sanitize_body, @raw_text)
    #     assert_match /dummy\" class=\"external/, @document.send(:sanitize_body, @raw_text)
    #   end
    #   
    #   should "remove images" do
    #     assert_match /with  image/, @document.send(:sanitize_body, "text with <img src='http://council.gov.uk/image' /> image")
    #   end
    # end
    
    # should "delegate council to document_owner" do
    #   assert_equal @doc_owner.council, @document.council
    # end
  end
end
