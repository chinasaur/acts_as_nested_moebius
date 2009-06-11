$: << File.join(File.dirname(__FILE__), 'lib')
require 'acts_as_nested_moebius'
include ChinasaurLi::Acts::NestedMoebius # Helpful for testing...

ActiveRecord::Base.class_eval do
  include ChinasaurLi::Acts::NestedMoebius
end if Object.const_defined?('ActiveRecord')