require 'test_helper'

class DocumentUtilitiesTest < ActiveSupport::TestCase

  context "The DocumentUtilities module" do
    setup do
      # @client = DocumentUtilities::Client.new
    end
    
    context "when sanitizing text" do
      setup do
        @raw_text =<<-EOF
"some <font='Helvetica'>stylized text</font> with <a href='councillor22'>relative link</a> and an <a href='http://external.com/dummy'>absolute link</a> and a <a href='mailto:foo@test.com'>mailto link</a>. Also a nasty bit of code <script>
if (type!="")
        {
         document.write("<p>");
         document.write(type);
         document.write("</p>");
        }
</script> 
here and <img src='http://council.gov.uk/image' /> image and some <!--[if !supportLists]-->cruft<!--[endif]--> <![if !supportLists]>here<![endif]>"
EOF
        @sanitized_document = DocumentUtilities.sanitize(@raw_text)
      end
      
      should "return nil if raw_text blank" do
        assert_nil DocumentUtilities.sanitize(nil)
        assert_nil DocumentUtilities.sanitize('')
      end
      
      should "return safe text unchanged" do
        assert_equal 'This is safe text', DocumentUtilities.sanitize('This is safe text')
        
      end
      
      should "not convert relative urls to absolute ones" do
        assert_match /with <a href=\"councillor22/, @sanitized_document
      end

      should "not change urls of absolute links" do
        assert_match /an <a href=\"http:\/\/external\.com\/dummy\"/, @sanitized_document
      end
      
      should "not change urls of mailto links" do
        assert_match /a <a href=\"mailto:foo@test\.com/, @sanitized_document
      end

      should "add external class to all links" do
        assert_match /councillor22\" class=\"external/, @sanitized_document
        assert_match /dummy\" class=\"external/, @sanitized_document
      end

      should "remove images" do
        assert_match /and  image/, @sanitized_document
      end
      
      should "remove comments" do
        assert_match /some cruft/, @sanitized_document
        assert_match /cruft here/, @sanitized_document
      end
      
      should "remove unwanted tags" do
        assert_match /some stylized/, @sanitized_document
      end
      
      should "remove contents of script tags" do
        assert_no_match /script/, @sanitized_document
        assert_no_match /document\.write/, @sanitized_document
      end
      
      context "and base_url passed" do
        setup do
          @sanitized_document = DocumentUtilities.sanitize(@raw_text, :base_url => "http://www.council.gov.uk/document/some_page.htm?q=something")
        end

        should "convert relative urls to absolute ones based on url" do
          assert_match /with <a href=\"http:\/\/www\.council\.gov\.uk\/document\/councillor22/, @sanitized_document
        end

        should "not change urls of absolute links" do
          assert_match /an <a href=\"http:\/\/external\.com\/dummy\"/, @sanitized_document
        end
        
        should "not change urls of mailto links" do
          assert_match /a <a href=\"mailto:foo@test\.com/, @sanitized_document
        end
      end
    end
    
    context "when returning precis" do
      setup do
        @raw_text = "some <font='Helvetica'>stylized text</font> with <a href='councillor22'>relative link</a> and an <a href='http://external.com/dummy'>absolute link</a>.\n\r\n\n\n   \r\n\tAlso <script> something dodgy</script> here \r\nand <img src='http://council.gov.uk/image' /> image"*10
        @precis_of_text = DocumentUtilities.precis(@raw_text)
      end

      should "return nil if raw_text blank" do
        assert_nil DocumentUtilities.precis('')
        assert_nil DocumentUtilities.precis(nil)
      end
      
      should "remove all tags" do
        assert_no_match %r(<.+>), @precis_of_text
      end
      
      should "not remove text in tags" do
        assert_match %r(some stylized text with relative link), @precis_of_text
      end
      
      should "trim multiple line spaces to single space" do
        assert_match %r(absolute link.\nAlso), @precis_of_text
      end
      
      should "trim to 500 chars in length" do
        assert_equal 500, @precis_of_text.length
      end
    end
    
  end
end