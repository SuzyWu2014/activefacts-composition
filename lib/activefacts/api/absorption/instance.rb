module ActiveFacts
  module API
    module Instance
      module Absorption
	module ClassMethods
	  # Define new methods for all ObjectTypes here:
	  attr_reader :absorb

	  def absorbs *a
	    # foo = a.last.is_a?(Hash) && a.last.delete(:foo)
	    if a.size == 0
	      @absorb = true
	      return
	    end

	    @absorb = a
	    if @absorb.last.is_a?(Hash) and @absorb.last.size > 1
	      # Break a hash into single-element hashes
	      @absorb.pop.each do |k, v|
		@absorb.push({k => v})
	      end
	    end
	  end

	  def absorption path = nil
	    @absorption ||= begin
#	      puts "Calculating absorption for #{self} with absorb=#{@absorb} and path #{path.inspect}"

	      if @absorb
		@absorb.inject({}) do |absorption, a|
		  case a
		  when Hash
		    role = roles(a.keys.first)
		    sub_roles = a.values.first
		    raise "Absorbed roles must be enumerable, not #{sub_roles.inspect}" unless sub_roles.is_a?(Enumerable)
		    # absorb the requested sub_roles
		    absorption[role.name] = sub_roles.inject({}) do |sub_absorption, role|
		      counterpart_object_type = role.counterpart.object_type
		      s = counterpart_object_type.absorption(role)
		      sub_absorption[
			role.counterpart.name # This is incorrect; what to use instead?
		      ] = s
		      sub_absorption
		    end
		  when Symbol
		    role = roles(a)
		    # Fully absorb all identifying roles of the player of this role
		    absorption[role.name] = role.name
		  else
		    raise "Unrecognised absorption type #{a.inspect}"
		  end
		  absorption
		end
	      else
		# This object is not prime, but gets absorbed into other objects
		# Return only its identifying roles
		r = self.class.identifying_roles
		debugger
		{}
	      end
	    end
	  end
	end

	# Define new methods for all Instances here:
      end
    end
  end
end
