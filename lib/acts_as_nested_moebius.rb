require 'moebius_interval'

module ChinasaurLi
  module Acts
    module NestedMoebius
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        
        def acts_as_nested_moebius
          extend(SingletonMethods)
        end
        
        module SingletonMethods
        end
        
      end
      
    end
  end
end
