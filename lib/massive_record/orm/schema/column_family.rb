module MassiveRecord
  module ORM
    module Schema
      class ColumnFamily
        attr_reader :name

        def initialize(name)
          self.name = name
        end

        def ==(other)
          other.instance_of?(self.class) && other.name == name
        end
        alias_method :eql?, :==

        def name=(name)
          raise ArgumentError.new("Name can't be blank!") if name.blank?
          @name = name.to_s
        end
      end
    end
  end
end
