module ActiveFacts
  module API
    module Value
      module Absorption
	module ClassMethods
	  # Define new absorption methods for Value classes here:
	end

	# Define new absorption methods for Value instances here:
      end

      # Prepend new methods for Values:
      prepend ActiveFacts::API::Instance::Absorption
      prepend Absorption

      # Prepend new methods for Value classes:
      module ClassMethods
	prepend ActiveFacts::API::Instance::Absorption::ClassMethods
        prepend Absorption::ClassMethods
      end
    end
  end
end
