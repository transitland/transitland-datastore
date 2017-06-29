# WARNING: a monkey patch from
# http://stackoverflow.com/a/20912826/40956

module Squeel
  module Nodes
    module Operators
      def within *list
        list = "{#{list.map(&:to_s).join(',')}}"
        Operation.new self, :'@>', list
      end
    end
  end
end

# WARNING: a monkey patch from
# https://stackoverflow.com/questions/31860441/deprecation-warning-modifying-already-cached-relation-on-postgres-max-greates
# to handle:
#   DEPRECATION WARNING: Modifying already cached Relation. The cache will be reset.
module Squeel
  module Adapters
    module ActiveRecord
      module RelationExtensions

        def execute_grouped_calculation(operation, column_name, distinct)
          super
        end

      end
    end
  end
end
