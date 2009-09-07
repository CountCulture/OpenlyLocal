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
  f.sequence(:uid) { |n| 76 + n }
  f.sequence(:url) { |n| "http://www.anytown.gov.uk/members/bob#{n}" }
  f.association :council
end

Factory.define :old_member, :class => :member, :parent => :member do |f|
  f.full_name "Old Yeller"
  f.url "http://www.anytown.gov.uk/members/yeller"
  f.date_left 6.months.ago
end

Factory.define :committee do |f|
  f.sequence(:uid) {|n| 76 + n }
  f.association :council
  f.sequence(:title) { |n| "Committee Number #{n}" }
  f.sequence(:url) { |n| "http://www.anytown.gov.uk/committee/#{76+n}" }
end

Factory.define :meeting do |f|
  f.sequence(:uid) { |n| 122 + n }
  f.association :council
  f.association :committee
  f.date_held 2.weeks.ago
  f.sequence(:url) { |n| "http://www.anytown.gov.uk/meeting/#{122+n}" }
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

Factory.define :dataset do |f|
  f.key "abc123"
  f.title "Dummy dataset"
  f.query "some query"
end

Factory.define :datapoint do |f|
  f.association :council
  f.association :dataset
  f.data        "some data"
end

Factory.define :ward do |f|
  f.name "Foo South"
  f.association :council
end