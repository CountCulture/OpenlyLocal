module ScrapedModel
  # This base module should be included in all models (except councils) that are 
  # scraped from Local Authority websites, e.g. members, committees. It adds 
  # functionality shared across all such clases, such as to allows changes to
  # be kept in instance even after safe, and provides basic #find_existing and
  # similar methods (which may be overrided in the class itself) which allows
  # objects to be found given the council and their uid
  module Base
    module ClassMethods
    
      def association_extension_attributes
        if const_defined?("AssociationAttributes")
          self::AssociationAttributes
        else
          [:uid]
        end
      end

      # class method to create bunch of useful methods to allow getting and setting of associated model attributes.
      # Use as :allow_access_to :children, :via => some_attrib
      # which gives Parent.child_some_attribs and the more useful
      # Parent.child_some_attribs = [attrib1, attrib2,...] which creates
      # parent-child relationships with Child instances identified
      # by Parent.council_id and attrib1, attrib2, ...
      def allow_access_to(relationship, options={})
        [options[:via]].flatten.each do |attrib|
          define_method "#{relationship.to_s.singularize}_#{attrib.to_s.pluralize}" do 
            self.send(relationship).collect(&(attrib.to_sym))
          end
          define_method "#{relationship.to_s.singularize}_#{attrib.to_s.pluralize}=" do |attrib_array|
            # extend normalising to other attributes in the future? 
            attrib_array = attrib_array.collect{|i| TitleNormaliser.normalise_title(i)} if attrib.to_s.match(/^normalised_title/) 
            assoc_klass = relationship.to_s.classify.constantize
            assoc_members = assoc_klass.send("find_all_by_council_id_and_#{attrib}", self.council_id, attrib_array)
            self.send("#{relationship}=", assoc_members)
          end
        end
      end


     # default find_existing. Overwrite in models that include this mixin if necessary
      def find_existing(params)
        return if params[:uid].blank? || params[:council_id].blank?
        find_by_council_id_and_uid(params[:council_id], params[:uid])
      end

      def build_or_update(params)
        existing_record = find_existing(params)
        existing_record.attributes = params if existing_record
        existing_record || self.new(params)
      end
    
      def create_or_update_and_save(params)
        updated_record = self.build_or_update(params)
        updated_record.save_without_losing_dirty
        updated_record
      end
    
      def create_or_update_and_save!(params)
        updated_record = build_or_update(params)
        updated_record.save_without_losing_dirty || raise(ActiveRecord::RecordNotSaved)
        updated_record
      end
    end
  
    module InstanceMethods
      # RAILS3 This will probably not be necessary when upgraded to RAILS 3.0
      def save_without_losing_dirty
        ch_attributes = changed_attributes.clone
        success = save # this clears changed attributes
        changed_attributes.update(ch_attributes) # so merge them back in
        success # return result of saving
      end
    
      def new_record_before_save?
        instance_variable_get(:@new_record_before_save)
      end
      
      # override this in individual classes to return object's status (e.g. "active", "future", etc)
      def status
      end
    
      def to_param
        id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
      end

      protected
      # Updates timestamp of council when member details are updated, new member is added or deleted
      def mark_council_as_updated
        council.update_attribute(:updated_at, Time.now) if council
      end
    end
  
    def self.included(i_class)
      i_class.extend         ClassMethods
      i_class.send :include, InstanceMethods
      i_class.after_save :mark_council_as_updated
      i_class.after_destroy :mark_council_as_updated
    end
  end
  
  # This module should be included in associations to allow relationships to be 
  # set given just a collection of uids. So if we have in the Committee model:
  # # has_many :members, :through => :memberships, :extend => UidAssociationExtension
  # this will add: members.uids and members.uids= methods. For convenience these can
  # be rewritten as member_uids and member_uids= using :delegate e.g.
  # # delegate :uids, :to => :members, :prefix => "member" 
  # which delegates the member_uids method to the uids method of the members 
  # association.
  # See http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html
  # for more details

  module UidAssociationExtension
    # THis is now DEPRECATED in favour of allow_access_to class method
    def add_or_update(members)
      # not yet done
    end

    def uids=(uid_array)
      uid_klass = proxy_reflection.source_reflection.try(:klass) || proxy_reflection.klass # see if there's a source reflection (i.e. HM Through), otherwise assume we have straight HM relationship
      uid_members = uid_klass.find_all_by_uid_and_council_id(uid_array, proxy_owner.council_id)
      proxy_owner.send("#{proxy_reflection.name}=",uid_members)
    end

    def uids
      collect(&:uid)
    end

  end
end

