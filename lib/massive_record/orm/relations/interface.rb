module MassiveRecord
  module ORM
    module Relations
      module Interface
        extend ActiveSupport::Concern

        included do
          class_attribute :relations, :instance_writer => false
          self.relations = nil
        end


        module ClassMethods
          #
          # Used to define a references one relation. Example of usage:
          # 
          # class Person < MassiveRecord::ORM::Table
          #   column_family :info do
          #     field :name
          #   end
          #   
          #   references_one :boss, :class_name => "Person", :store_in => :info
          # end
          #
          # First argument is the name of the relation. class_name and foreign key is calculated from it, if none given.
          #
          #
          # Options, all optional:
          #
          #   <tt>class_name</tt>::   Class name is calculated from name, but can be overridden here.
          #   <tt>polymorphic</tt>::  Set it to true for make the association polymorphic. Will use foreign_key,
          #                           remove the "_id" (if it's there) and add _type for it's reading/writing of type.
          #   <tt>foreign_key</tt>::  Foreign key is calculated from name suffixed by _id as default.
          #   <tt>store_in</tt>::     Send in the column family to store foreign key in. If none given,
          #                           you should define the foreign key method in class if it can be
          #                           calculated from another attributes in your class.
          #   <tt>find_with</tt>::    Assign it to a Proc and we will call it with the owner if you need complete
          #                           control over how you retrieve your record.
          #                           As a default TargetClass.find(foreign_key_method) is used.
          #
          def references_one(name, *args)
            ensure_relations_exists

            metadata = Metadata.new(name, *args)
            metadata.relation_type = 'references_one'
            raise RelationAlreadyDefined unless self.relations.add?(metadata)
            create_references_one_accessors(metadata)
            create_references_one_polymorphic_accessors(metadata) if metadata.polymorphic?
          end


          #
          # Used to define a reference many relation. Example of usage:
          # 
          # class Person < MassiveRecord::ORM::Table
          #   column_family :info do
          #     field :name
          #   end
          #   
          #   references_many :cars, :store_in => :info
          # end
          #
          # First argument is the name of the relation. class_name and attribute for foreign keys are calculated from it,
          # if noen given. In the example above Person records will have attribute cars_ids which will be
          # an array populated with foreign keys.
          #
          #
          # Options, all optional:
          #
          #   <tt>class_name</tt>::   Class name is calculated from name, but can be overridden here.
          #   <tt>foreign_key</tt>::  Foreign key is calculated from name suffixed by _ids as default.
          #   <tt>store_in</tt>::     Send in the column family to store foreign key in. If none given,
          #                           you should define the foreign key method in class if it can be
          #                           calculated from another attributes in your class.
          #   <tt>starts_with</tt>::  A method name which returns an ID to start from when fetching rows in
          #                           Person's table. This is useful if you for instance has a person with id 1
          #                           and in your table for cars have cars id like "<person_id>-<incremental number>"
          #                           or something. Then you can say references_many :cars, :starts_with => :id.
          #   <tt>find_with</tt>::    Assign it to a Proc and we will call it with the owner if you need complete
          #                           control over how you retrieve your record.
          #                           As a default TargetClass.find(foreign_keys_method) is used.
          #
          #
          def references_many(name, *args)
            # TODO
          end

          private

          def ensure_relations_exists
            self.relations = Set.new if relations.nil?
          end


          def create_references_one_accessors(metadata)
            redefine_method(metadata.name) do
              proxy = relation_proxy(metadata.name)
              proxy.load_target ? proxy : nil
            end

            redefine_method(metadata.name+'=') do |record|
              relation_proxy(metadata.name).replace(record)
            end

            if metadata.persisting_foreign_key?
              add_field_to_column_family(metadata.store_in, metadata.foreign_key)
            end
          end

          def create_references_one_polymorphic_accessors(metadata)
            if metadata.persisting_foreign_key?
              add_field_to_column_family(metadata.store_in, metadata.polymorphic_type_column)
            end
          end
        end



        private

        def relation_proxy(name)
          name = name.to_s

          unless proxy = relation_proxy_get(name)
            if metadata = relations.find { |meta| meta.name == name }
              proxy = metadata.new_relation_proxy(self)
              relation_proxy_set(name, proxy)
            end
          end

          proxy
        end

        def relation_proxy_get(name)
          @relation_proxy_cache[name.to_s]
        end

        def relation_proxy_set(name, proxy)
          @relation_proxy_cache[name.to_s] = proxy
        end
      end
    end
  end
end
