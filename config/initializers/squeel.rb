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
