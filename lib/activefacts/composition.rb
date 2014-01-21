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

    class Absorption
      attr_reader :vocabulary		# Vocabulary
      attr_reader :parent		# Absorption
      attr_reader :name			# String
      attr_reader :object_type		# Class (EntityType or ValueType)
      attr_reader :traversals		# Array[role_name (or Role?)] (at most one non-unique role)
      attr_reader :members		# => Enumerable(Absorption)

      def initialize(vocabulary, parent, name, object_type)
	@vocabulary = vocabulary
	@parent = parent
	@name = name
	@object_type = object_type
	@traversals = []
	@members = []
      end

      # Every Absorption is either an absorbed value or is a Composite
      def is_composite
	members && members.size > 0
      end

      def include role_name, *a, &b
	hash = a.last.is_a?(Hash) ? a.pop : {}
	role = @object_type.roles(role_name)
	puts "#{indent}Including #{role.name} with options #{hash.inspect}"
	klass = role.counterpart.object_type
	absorption = Absorption.new(@vocabulary, self, hash[:as] || role_name.to_s, klass)
	absorption.traversals << role_name
	absorption.contents(*a, &b)
	members << absorption
      end

      def contents(*a, &b)
	# Include the identifying roles of an EntityType:
	if @object_type.respond_to?(:identifying_roles)
	  # puts "including #{@object_type.identifying_role_names.inspect}"
	  # Include the identifying_roles of @object_type
	  @object_type.identifying_roles.each do |role|
	    puts "#{indent}Including identifying #{role.name}"
	    absorption = Absorption.new(@vocabulary, self, role.name, role.counterpart.object_type)
	    absorption.traversals << role.name
	    absorption.contents
	    members << absorption
	  end
	end

	self.instance_exec(&b) if b
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
      hash = a.last.is_a?(Hash) ? a.pop : {}
      puts "#{indent}Compositing #{klass} with options #{hash.inspect}"
      absorption = Absorption.new(@vocabulary, self, sym.to_s, klass)
      absorption.contents(*a, &b)
      members << absorption
    end

    def indent
      ''
    end
  end

  # Vocabulary.composition("Name") => Composition
  # ObjectType.composition("Name") => Absorption
end
