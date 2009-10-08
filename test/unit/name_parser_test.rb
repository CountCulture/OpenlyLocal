require 'test_helper'

class NameParserTest < Test::Unit::TestCase
  OriginalNameAndParsedName = {
    "Fred Flintstone" => {:first_name => "Fred", :last_name => "Flintstone"},
    "Fred Bob Flintstone" => {:first_name => "Fred Bob", :last_name => "Flintstone"},
    "Fred-Bob Flintstone" => {:first_name => "Fred-Bob", :last_name => "Flintstone"}, 
    "Fred Flintstone-May" => {:first_name => "Fred", :last_name => "Flintstone-May"},
    "Fred Bob William Flintstone" => {:first_name => "Fred Bob William", :last_name => "Flintstone"},
    "Councillor Fred Flintstone" => {:first_name => "Fred", :last_name => "Flintstone"},
    "Councillor \r\n    Fred  Flintstone  " => {:first_name => "Fred", :last_name => "Flintstone"},
    "Councillor Fred Flintstone C.B.E." => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "C.B.E."},
    "Councillor Fred Flintstone MBA" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "MBA"},
    "Councillor Fred Flintstone OBE" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "OBE"},
    "Fred Flintstone OBE CC" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "OBE"},
    "Councillor R.B. Flintstone, M.B.E." => {:first_name => "R B", :last_name => "Flintstone", :qualifications => "M.B.E."},
    "Councillor Fred Flintstone" => {:first_name => "Fred", :last_name => "Flintstone"}, #lose typos too
    "Councilllor WMJ Flintstone" => {:first_name => "WMJ", :last_name => "Flintstone"}, 
    "Mr Fred Flintstone" => {:name_title => "Mr", :first_name => "Fred", :last_name => "Flintstone"},
    "Mr#{160.chr}Fred Flintstone" => {:name_title => "Mr", :first_name => "Fred", :last_name => "Flintstone"},
    "Mr Barry Abraham" => {:name_title => "Mr", :first_name => "Barry", :last_name => "Abraham"}, # spaces in this are actually not usual ascii space
    "Ms Siobhán Dorée" => {:name_title => "Ms", :first_name => "Siobhán", :last_name => "Dorée"},
    " \r\n\t  Mr&nbsp;Fred&nbsp;Flintstone" => {:name_title => "Mr", :first_name => "Fred", :last_name => "Flintstone"},
    "Mr Fred McFlintstone" => {:name_title => "Mr", :first_name => "Fred", :last_name => "McFlintstone"},
    "Prof Dr Fred Flintstone" => {:name_title => "Prof Dr", :first_name => "Fred", :last_name => "Flintstone"},
    "Prof Mr Fred Flintstone" => {:name_title => "Prof Mr", :first_name => "Fred", :last_name => "Flintstone"},
    "Sir Fred Flintstone" => {:name_title => "Sir", :first_name => "Fred", :last_name => "Flintstone"},
    "Councillor R.S.Dixon" => {:first_name => "R S", :last_name => "Dixon"},
    "Dr Fred Flintstone" => {:name_title => "Dr", :first_name => "Fred", :last_name => "Flintstone"},
    "Dr. Fred Flintstone" => {:name_title => "Dr", :first_name => "Fred", :last_name => "Flintstone"},
    "Councillor Mrs Wilma Flintstone" => {:name_title => "Mrs", :first_name => "Wilma", :last_name => "Flintstone"},
    "Councillor Mrs. Wilma Flintstone" => {:name_title => "Mrs", :first_name => "Wilma", :last_name => "Flintstone"},
    "Councillor Mrs. Flintstone" => {:name_title => "Mrs", :first_name => "", :last_name => "Flintstone"},
    "Councillor Flintstone" => {:first_name => "", :last_name => "Flintstone"},
    "Cllr Fred Flintstone" => {:first_name => "Fred", :last_name => "Flintstone"},
    "Professor Fred H. Flintstone" => {:name_title => "Professor", :first_name => "Fred H", :last_name => "Flintstone"},
    "Fred Flintstone BSc" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "BSc"},
    "Fred Flintstone B.Sc." => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "B.Sc."},
    "Fred Flintstone BSc, PhD" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "BSc PhD"},
    "Councillor MAF Flintstone" => {:first_name => "MAF", :last_name => "Flintstone"},
    "Fred Flintstone BSc, MRTPI(Rtd)" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "BSc"},
    "Councillor B. Lewis F.CMI" => {:first_name => "B", :last_name => "Lewis", :qualifications => "F.CMI"},
    "Fred Flintstone MInstTA" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "MInstTA"},
    "Fred Flintstone MBCS CITP" => {:first_name => "Fred", :last_name => "Flintstone"},  
    "Fred Flintstone B.Ed. Hons" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "B.Ed. Hons"},
    "Fred Flintstone BSc (Eng) MBA MIET" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "BSc MBA"},
    "Fred Flintstone BA Hons" => {:first_name => "Fred", :last_name => "Flintstone", :qualifications => "BA Hons"},
    "The Right Honourable the Lord Mayor Fred Flintstone" => {:first_name => "Fred", :last_name => "Flintstone", :name_title => "The Right Honourable the Lord Mayor"},
    "High Sheriff Fred Flintstone" => {:first_name => "Fred", :last_name => "Flintstone", :name_title => "High Sheriff"},
    "The Deputy Mayor Fred Flintstone" => {:first_name => "Fred", :last_name => "Flintstone", :name_title => "The Deputy Mayor"},
    "Councillor Fred Flintstone (Leader of the Council)" => {:first_name => "Fred", :last_name => "Flintstone"},
    "Councillor Fred Flintstone - The Mayor" => {:first_name => "Fred", :last_name => "Flintstone"},
    "Councillor Fred Flintstone - Some Other Title" => {:first_name => "Fred", :last_name => "Flintstone"},
    "Matthew Holmes" => {:first_name => "Matthew", :last_name => "Holmes"},
    "Jane Annabel Wilson (nee Allen)" => {:first_name => "Jane Annabel", :last_name => "Wilson"}    
  }
  
  context "The NameParser module" do

    should "parse first name and last name from name" do
      OriginalNameAndParsedName.each do |orig_name, parsed_values|
        assert_equal( parsed_values, NameParser.parse(orig_name), "failed for #{orig_name}")
      end
    end

  end
  
end