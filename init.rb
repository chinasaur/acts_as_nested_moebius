if Object.const_defined?('ActiveRecord')
  require 'acts_as_nested_moebius'
  ActiveRecord::Base.class_eval{include ChinasaurLi::Acts::NestedMoebius}
end