module ScrapedModel
  # This base module should be included in all models (except councils) that are 
  # scraped from Local Authority websites, e.g. members, committees. It adds 
  # functionality shared across all such clases, such as to allows changes to
  # be kept in instance even after safe, and provides basic #find_all_existing and
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
          belong_to_rel = reflections[relationship.to_sym].macro == :belongs_to
          # if relationship is belongs_to relationship don't pluralize attribname
          attrib_meth_name = belong_to_rel ? attrib.to_s : attrib.to_s.pluralize 
          define_method "#{relationship.to_s.singularize}_#{attrib_meth_name}" do 
            belong_to_rel ? self.send(relationship).send(attrib.to_sym) : self.send(relationship).collect(&(attrib.to_sym))
          end
          define_method "#{relationship.to_s.singularize}_#{attrib_meth_name}=" do |attrib_array|
            # extend normalising to other attributes in the future? 
            attrib_array = attrib_array.collect{|i| TitleNormaliser.normalise_title(i)} if attrib.to_s.match(/^normalised_title/) 
            assoc_klass = relationship.to_s.classify.constantize
            assoc_members = belong_to_rel ? assoc_klass.send("find_by_council_id_and_#{attrib}", self.council_id, attrib_array) : 
                                            assoc_klass.send("find_all_by_council_id_and_#{attrib}", self.council_id, attrib_array)
            self.send("#{relationship}=", assoc_members)
            self.save
          end
        end
      end



      # default find_all_existing. By default finds for instances of model associated 
      # with council as specified in params[:council_id]. Overwrite in models that need 
      # more specific behaviour, e.g. Meeting model should return only meetings 
      # associated with given council and committe
      def find_all_existing(params)
        raise ArgumentError, ":council_id is missing from submitted params" if params[:council_id].blank? 
        find_all_by_council_id(params[:council_id])
      end

      def build_or_update(params_array, options={})
        return if params_array.blank?
        exist_records = find_all_existing(params_array.first.merge(:council_id => options[:council_id])) # want council_id and other params (e.g. committee_id) that *might* be necessary to find all existing records
        results = [params_array].flatten.collect do |params| #make into array if it isn't one
          if result = exist_records.detect{ |r| r.matches_params(params) }
            result.attributes = params
            exist_records.delete(result)
          end
          result ||= record_not_found_behaviour(params.merge(:council_id => options[:council_id]))
          options[:save_results] ? result.save_without_losing_dirty : result.valid? # we want to know what's changed and keep any errors, so run save_without_losing_dirty if we're saving, run validation to add errors to item otherwise
          logger.debug { "**********result = #{result.inspect}" }
          ScrapedObjectResult.new(result)
        end
        orphan_records_callback(exist_records, :save_results => options[:save_results])
        results
      end
      
      # Generic class method for normalising title. Calls TitleNormalizer.normalise by default but 
      # can be overridden in individual models if something more is needed (e.g. to remove 'Committee' 
      # from the name). Note this is public class method so that it can be easily called from rake 
      # tasks etc
      def normalise_title(raw_title)
        TitleNormaliser.normalise_title(raw_title)
      end
      
      protected
      # stub method. Is called in build_or_update with those records that
      # are in db but that weren't returned by scraper/parser (for example old 
      # commitees/meetings/councillors). By default does nothing. However may 
      # be overridden in model class, e.g. to mark events as defunct in some way
      def orphan_records_callback(recs=nil, opts={})
      end
      
      # default record_not_found_behaviour. Overwrite in models that include this mixin if necessary
      def record_not_found_behaviour(params)
        self.new(params)
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
      
      # override this in individual classes to define whether params from scraper parser are the same
      # record as current one. By default this is if the uid is the same (we should only be matching 
      # against records from the correct council so don't need to check council_id)
      def matches_params(params={})
        params[:uid].blank? ? false : (params[:uid] == self[:uid]) 
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

      def openlylocal_url
        "http://#{DefaultDomain}/#{self.class.table_name}/#{to_param}"
      end

      def resource_uri
        "http://#{DefaultDomain}/id/#{self.class.table_name}/#{id}"
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
  
end

