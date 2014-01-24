require 'activefacts/api'
# require 'activefacts/composition/vocabulary'
# require 'activefacts/composition/instance'
# require 'activefacts/composition/value'
# require 'activefacts/composition/entity'
# require 'activefacts/composition/constellation'

module ActiveFacts
  # A Composition is a way of arranging the ObjectTypes that make up a vocabulary
  # to form a particular kind of composite schema, for example, normalised ER,
  # object-oriented, analytic (star), non-first-normal-form (N1NF).
  # Each Composition contains a number of Composites as members.
  # A Composite is an Absorption, and an Absorption may have nested Absorptions.
  class Composition
    attr_reader :vocabulary
    attr_reader :name
    attr_reader :members

    def inspect
      "#{name}"
    end

    def tree
      "#{name || vocabulary.name}\n"+
      members.map do |m|
	m.tree
      end * "\n\n"
    end

    def traversals
      []
    end

    class Absorption
      attr_reader :vocabulary		# Vocabulary
      attr_reader :parent		# Absorption
      attr_reader :name			# String
      attr_reader :object_type		# Class (EntityType or ValueType)
      attr_reader :traversals		# Array[role_name (or Role?)] (at most one non-unique role)
      attr_reader :members		# => Enumerable(Absorption)

      def inspect
	"#{parent ? parent.inspect+'.' : ''}#{object_type.basename}"
      end

      def tree
	(
	  [ "#{indent}#{name || vocabulary.name}" ] +
	  members.map do |m|
	    m.tree
	  end
	) * "\n"
      end

      def initialize(vocabulary, parent, name, object_type)
	@vocabulary = vocabulary
	@parent = parent
	@name = name
	@object_type = object_type
	@traversals = []
	@members = []
	@exclude_role = nil
      end

      # Every Absorption is either an absorbed value or is a Composite
      def is_composite
	members && members.size > 0
      end

      def include role_name, *a, &b
	hash = a.last.is_a?(Hash) ? a.pop : {}
	role = @object_type.roles(role_name)
	puts "#{indent}Including #{hash[:as] || role.name}" # with options #{hash.inspect}
	klass = (c = role.counterpart) ? c.object_type : @vocabulary.object_type('ImplicitBooleanValueType')
	absorption = Absorption.new(@vocabulary, self, hash[:as] || role_name.to_s, klass)
	absorption.traversals << role
	absorption.contents(role, *a, &b)
	members << absorption
      end

      def absorb role_name = nil, *a, &b
	if role_name
	  include role_name, *a do
	    all_functionals
	    instance_exec(&b) if b
	  end
	else
	  all_functionals *a, &b
	end
      end

      def all_functionals
	candidates = @object_type.roles.keys
	exclude = @object_type.respond_to?(:identifying_role_names) ? @object_type.identifying_role_names : []
	exclude << @exclude_role.counterpart.name if @exclude_role
	functional_role_names = (candidates-exclude).reject do |role_name|
	    role = @object_type.roles(role_name)
	    !role.unique || ((c = role.counterpart) && c.unique)
	  end
	functional_role_names.each do |role_name|
	  puts "#{indent}Functional #{role_name}"
	  include role_name
	end
      end

      def contents(exclude_role = nil, *a, &b)
	# Include the identifying roles of an EntityType:
	if @object_type.respond_to?(:identifying_roles)
	  # puts "including #{@object_type.identifying_role_names.inspect}"
	  # Include the identifying_roles of @object_type
	  @object_type.identifying_roles.each do |role|
	    next if role == false   ## WTF? Constraint has an identifying_role of "false"
	    next if (exclude_role == role.counterpart)	# Skip implicit source role
	    puts "#{indent}Including identifying #{role.name}"
	    klass = (c = role.counterpart) ? c.object_type : @vocabulary.object_type('ImplicitBooleanValueType')
	    absorption = Absorption.new(@vocabulary, self, role.name, klass)
	    absorption.traversals << role
	    absorption.contents role
	    members << absorption
	  end
	end

	if b
	  old_exclude = @exclude_role
	  @exclude_role = exclude_role
	  instance_exec(&b)
	  @exclude_role = old_exclude
	end
      end

      def indent
	parent ? parent.indent+'  ' : ''
      end
    end

    # New Composition over a vocabulary
    def initialize(vocabulary, &b)
      @vocabulary = vocabulary
      if !@vocabulary.is_a?(Module)
	raise "A Composition must operate on a Vocabulary module, not #{@vocabulary.inspect}"
      end

      @members = []

      instance_exec(&b)	# Call the block in our own context (makes composite available)
    end

    def composite(sym, *a, &b)
      klass = @vocabulary.object_type(sym)
      raise "Object Type #{sym} is not known" unless klass
      hash = a.last.is_a?(Hash) ? a.pop : {}
      puts "#{indent}Compositing #{klass.basename}" #  with options #{hash.inspect}
      absorption = Absorption.new(@vocabulary, self, sym.to_s, klass)
      absorption.contents(nil, *a, &b)
      members << absorption
    end

    # Return an array of the roles which are not covered by this composition
    # REVISIT: This doesn't capture the case where a role is covered for one subtype but not the supertype or siblings
    def missing_roles
      role_hash = unmarked_roles
      mark_role(role_hash, self)
      role_hash.reject{|k,v| v}.keys
    end

    def indent
      ''
    end

private
    # Return a hash of every role used in this Composition (as key) with value false
    def unmarked_roles
      vocabulary.object_type.values.inject({}) do |h, o|
	o.roles.map do |k,v|
	  h[v] = false
	end
	h
      end
    end

    # Recursively descend the Composition marking all roles used in traversals
    def mark_role(role_hash, absorption)
      absorption.traversals.each do |role|
	role_hash[role] = true
	role_hash[role.counterpart] = true if role.counterpart
      end
      absorption.members.each do |x|
	mark_role(role_hash, x)
      end
    end
  end
end
