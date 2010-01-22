Factory.define :scraper, :class => :item_scraper do |s|
  # s.url 'http://www.anytown.gov.uk/members/bob'
  s.association :parser
  s.association :council
end

Factory.define :item_scraper, :class => :item_scraper do |s|
  s.url 'http://www.anytown.gov.uk/members'
  s.association :parser
  s.association :council, :factory => :tricky_council
end

Factory.define :info_scraper, :class => :info_scraper do |s|
  s.association :parser, :factory => :another_parser
  s.association :council, :factory => :another_council
end

Factory.define :parser do |f|
  f.description 'description of dummy parser'
  f.item_parser  'foo="bar"'
  f.result_model 'Member'
  f.scraper_type 'ItemScraper'
  f.attribute_parser({:foo => "\"bar\"", :foo1 => "\"bar1\""})
end

Factory.define :another_parser, :parent => :parser do |f|
  f.description 'another dummy parser'
  f.scraper_type 'InfoScraper'
end

Factory.define :council do |f|
  f.name 'Anytown'
  f.url 'http://www.anytown.gov.uk'
end
Factory.define :another_council, :class => :council do |f|
  f.name 'Anothertown'
  f.url 'http://www.anothertown.gov.uk'
end
Factory.define :tricky_council, :class => :council do |f|
  f.name 'Tricky Town'
  f.url 'http://www.trickytown.gov.uk'
end

Factory.define :member do |f|
  f.sequence(:full_name) { |n| "Bob Wilson#{n}" }
  f.sequence(:uid) { |n| (76 + n).to_s }
  f.sequence(:url) { |n| "http://www.anytown.gov.uk/members/bob#{n}" }
  f.association :council
end

Factory.define :old_member, :class => :member, :parent => :member do |f|
  f.full_name "Old Yeller"
  f.url "http://www.anytown.gov.uk/members/yeller"
  f.date_left 6.months.ago
end

Factory.define :committee do |f|
  f.sequence(:uid) {|n| (76 + n).to_s }
  f.association :council
  f.sequence(:title) { |n| "Committee Number #{n}" }
  f.sequence(:url) { |n| "http://www.anytown.gov.uk/committee/#{76+n}" }
end

Factory.define :meeting do |f|
  f.association :council
  f.association :committee
  f.sequence(:date_held){ |n| "20 September 2009".to_datetime - n.minutes }
end

Factory.define :portal_system do |f|
  f.name 'SuperPortal'
  f.url "http://www.superportal.com"
end

Factory.define :document do |f|
  f.sequence(:url) { |n|  "http://www.council.gov.uk/document/#{32+n}" }
  f.raw_body "This is raw text"
  f.body "This is a document. It goes " + "on and on and on"*10
end

Factory.define :old_dataset do |f|
  f.key "abc123"
  f.title "Dummy dataset"
  f.query "some query"
end

Factory.define :old_datapoint do |f|
  f.association :council
  f.association :old_dataset
  f.data        "some data"
end

Factory.define :ward do |f|
  f.name "Foo South"
  f.association :council
end

Factory.define :output_area do |f|
  f.sequence(:oa_code) { |n| "00AAFA000#{n}" }
  f.sequence(:lsoa_code) { |n|  "E0100000#{n}" }
  f.sequence(:lsoa_name) { |n|  "City of London 00#{n}" }
end

Factory.define :wdtk_request do |f|
  f.sequence(:title) { |n|  "FoI request Number #{n}" }
  f.sequence(:url) { |n|  "wdtk_url/#{n}" }
  f.association :council
end

Factory.define :officer do |f|
  f.sequence(:last_name) { |n| "Perfect#{n}" }
  f.position "Some Exec"
  f.association :council
end

Factory.define :feed_entry do |f|
  f.sequence(:title) { |n| "Feed Title #{n}" }
  f.sequence(:url) { |n|  "http://feed.com/#{n}" }
  f.sequence(:guid) { |n|  "guid_#{n}" }
end

Factory.define :cached_postcode do |f|
  f.sequence(:code) { |n| "AB1CD#{n}" }
end

Factory.define :ldg_service do |f|
  f.sequence(:category) { |n| "Foo #{n}" }
  f.sequence(:lgsl) { |n| 33 + n }
  f.lgil 56
  f.service_name "Foo Service"
  f.authority_level "district/unitary"
  f.url  "local.direct.gov.uk/LDGRedirect/index.jsp?LGSL=34&amp;LGIL=8&amp;ServiceName=Find out about pupil exclusions from school"
end

Factory.define :service do |f|
  f.sequence(:title) { |n| "Foo Service #{n}" }
  f.sequence(:category) { |n| "Foo Category #{n}" }
  f.sequence(:url) { |n| "http://council.gov.uk/foo/#{n}" }
  f.association :council
  f.association :ldg_service
end

Factory.define :police_force do |f|
  f.sequence(:name) { |n| "Force #{n}" }
  f.sequence(:url) { |n|  "http://police.uk/force#{n}" }
end

Factory.define :police_authority do |f|
  f.sequence(:name) { |n| "Police Authority #{n}" }
  f.sequence(:url) { |n|  "http://policeauthority.uk/force#{n}" }
  f.association :police_force
end

Factory.define :ons_subject do |f|
  f.sequence(:title) { |n| "Ons Subject #{n}" }
  f.sequence(:ons_uid) { |n| n }
end

Factory.define :dataset do |f|
  f.sequence(:title) { |n| "Dataset #{n}" }
  f.originator "ONS"
end

Factory.define :dataset_family do |f|
  f.sequence(:title) { |n| "Ons Dataset #{n}" }
  f.sequence(:ons_uid) { |n| n }
  f.source_type "Ness"
  f.association :dataset
end

Factory.define :ons_dataset do |f|
  f.sequence(:start_date) { |n| (2.years.ago - (n*5).days).to_date }
  f.sequence(:end_date) { |n| (2.years.ago - (n*5 - 2).days).to_date }
  f.association :dataset_family
end

Factory.define :dataset_topic do |f|
  f.sequence(:title) { |n| "Ons topic #{n}" }
  f.sequence(:ons_uid) { |n| 21+n }
  f.association :dataset_family
end

Factory.define :datapoint do |f|
  f.sequence(:value) { |n| 21+n }
  f.association :dataset_topic
  f.association :area, :factory => :ward
end

Factory.define :dataset_topic_grouping do |f|
  f.sequence(:title) { |n| "grouping_#{n}" }
end

Factory.define :hyperlocal_site do |f|
  f.sequence(:title) { |n| "Hyperlocal #{n}" }
  f.sequence(:url) { |n| "http://hyperlocal.co.uk/site_#{n}" }
  f.country 'England'
  f.description "Some about the site"
  f.distance_covered 2
  f.lat 52
  f.lng -1
end

Factory.define :approved_hyperlocal_site, :parent => :hyperlocal_site do |hs|
  hs.approved true
end

Factory.define :hyperlocal_group do |f|
  f.sequence(:title) { |n| "Hyperlocal Group #{n}" }
end

Factory.define :boundary do |f|
  f.association :area, :factory => :ward
  f.sequence(:bounding_box) { |n| Polygon.from_coordinates([[[1.0+0.1*n, 52.0+0.1*n], [2.0+0.1*n, 52.0+0.1*n], [2.0+0.1*n, 54.0+0.1*n], [1.0+0.1*n, 54.0+0.1*n], [1.0+0.1*n, 52.0+0.1*n]]]) } 
end
