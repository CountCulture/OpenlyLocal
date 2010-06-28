# These models are used in scraper_tests
class TestScrapedModel <ActiveRecord::Base
  attr_accessor :foo, :foo1
  attr_accessor :council
  include ScrapedModel::Base
  set_table_name "committees"
  has_many :test_child_models, :class_name => "TestChildModel", :foreign_key => "committee_id"
  has_many :test_join_models, :foreign_key => "committee_id"
  has_many :test_joined_models, :through => :test_join_models
  validates_presence_of :uid
  allow_access_to :test_child_models, :via => [:url, :uid]
end

class TestChildModel <ActiveRecord::Base
  belongs_to :test_scraped_model, :class_name => "TestScrapedModel", :foreign_key => "committee_id"
  AssociationAttributes = [:uid, :url]
  attr_accessor :council, :title, :foo1, :foo
  include ScrapedModel::Base
  set_table_name "meetings"
  allow_access_to :test_scraped_model, :via => [:uid, :title]
end

class TestJoinModel <ActiveRecord::Base
  set_table_name "memberships"
  belongs_to :test_scraped_model, :class_name => "TestScrapedModel", :foreign_key => "committee_id"
  belongs_to :test_joined_model, :foreign_key => "member_id"
end

class TestJoinedModel <ActiveRecord::Base
  attr_accessor :council
  include ScrapedModel::Base
  set_table_name "members"
  has_many :test_join_models, :foreign_key => "member_id"
  has_many :test_scraped_models, :through => :test_join_models
  allow_access_to :test_scraped_models, :via => [:uid, :normalised_title]
end

class TestModelWithSocialNetworking <ActiveRecord::Base
  include SocialNetworkingUtilities::Base
  set_table_name "members"
end

