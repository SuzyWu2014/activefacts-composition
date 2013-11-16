module ActiveFacts
  module API
    module Entity
      module Absorption
	module ClassMethods
	  # Define new Absorption methods for Entity classes:
	end

	# Define new absoption methods for Entity instances:
      end

      # Prepend new methods for Entities:
      prepend ActiveFacts::API::Instance::Absorption
      prepend Absorption

      # Prepend new methods for Entity classes:
      module ClassMethods
	prepend ActiveFacts::API::Instance::Absorption::ClassMethods
        prepend Absorption::ClassMethods
      end
    end
  end
end
