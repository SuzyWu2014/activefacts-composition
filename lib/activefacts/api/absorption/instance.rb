module ActiveFacts
  module API
    module Instance
      module Absorption
	module ClassMethods
	  # Define new methods for all ObjectTypes here:
	  def absorb *a
	    # foo = a.last.is_a?(Hash) && a.last.delete(:foo)
	  end
	end

	# Define new methods for all Instances here:
      end
    end
  end
end
