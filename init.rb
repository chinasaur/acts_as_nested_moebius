$: << File.join(File.dirname(__FILE__), 'lib')
require 'acts_as_nested_moebius'
 
ActiveRecord::Base.class_eval do
  include ChinasaurLi::Acts::NestedMoebius
end if Object.const_defined?('ActiveRecord')