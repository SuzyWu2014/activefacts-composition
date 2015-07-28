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
    attr_reader :members

    # Each absorption corresponds to one level of nesting
    class Absorption
      attr_reader :vocabulary		# Vocabulary
      attr_reader :parent		# Absorption or top-level Composite
      attr_reader :name			# String (role name or object type name) or nil (for flattening)
      attr_reader :role			#
      attr_reader :object_type		# Class (EntityType or ValueType)
      attr_reader :traversals		# Array[role_name (or Role?)] (at most one non-unique role)
      attr_reader :members		# => Enumerable(Absorption)
      attr_reader :options		# Options hash

      def inspect
	"Absorption #{vocabulary.name||'<null>'}.#{object_type.basename} as #{name} with #{members.size} members"
      end

      def initialize(vocabulary, parent, name, object_type, options = {})
	@vocabulary = vocabulary
	@object_type = object_type
	@options = options
	@traversals = []
	@members = []
	@exclude_role = nil

	@name = name
	if @object_type == []
	  # An array type, which has no object_type of its own
	  @role = parent.object_type.all_role(@name)
	  @object_type = nil
	elsif @object_type
	  @name ||= @object_type.basename
	else
	  @role = parent.object_type.all_role(@name)
	  @object_type = @role.unary? ? @vocabulary.object_type('ImplicitBooleanValueType') : @role.counterpart.object_type

	  # Create a parent wrapper around non-unique roles:
	  unless @role.unique
	    as = options.has_key?(:as) ? {:as => options.delete(:as)} : {}  # Awkward, maybe there's a better way.
	    parent = Absorption.new(vocabulary, parent, name, [], as)
	    parent.traversals << @role
	    @name = options.delete(:each) || @object_type.basename.snakecase
	    @role = nil
	  else
	    @traversals << @role
	  end

	end
	@name = options.delete(:as) if options.has_key?(:as)

	@parent = parent		# Absorption or Composition
	@parent.members << self
      end

      # Include just this role (and its contents if selected by the block)
      def nest role_name, *a, &b
	hash = a.last.is_a?(Hash) ? a.pop : {}
	raise "nest only allows role name and options" if a.size > 0

	absorption = Absorption.new(@vocabulary, self, role_name, nil, hash)

	role = absorption.role || absorption.parent.role
	absorption.contents(role, *a, &b) unless role.unary?
      end

      # Like nest, but with an anonymous Absorption that will not create a named nesting
      def flatten(role_name, *a, &b)
	hash = a.last.is_a?(Hash) ? a.pop : {}
	hash[:as] = nil
	a.push(hash)

	absorption = Absorption.new(@vocabulary, self, role_name, nil, hash)

	role = absorption.role || absorption.parent.role
	absorption.contents(role, *a, &b) unless role.unary?
      end

      # Recursively absorb all functional roles, or all FRs under the given role (and their contents if selected by the block)
      def absorb role_name = nil, &b
	if role_name
	  nest role_name do
	    all_functionals
	    instance_exec(&b) if b
	  end
	else
	  all_functionals &b
	end
      end

      # Include all has_one roles except identifying roles
      def all_functionals
	candidates = @object_type.all_role.keys
	exclude = @object_type.respond_to?(:identifying_role_names) ? @object_type.identifying_role_names : []
	exclude = exclude + [@exclude_role.counterpart.name] if @exclude_role
	functional_role_names = (candidates-exclude).reject do |role_name|
	    role = @object_type.all_role(role_name)
	    !role.unique || ((c = role.counterpart) && c.unique)
	  end
	namespace = self
	while namespace.name == nil
	  namespace = namespace.parent
	end
	functional_role_names.each do |role_name|
#	  puts "#{indent}Functional #{role_name}"
	  next if namespace.has_role role_name
	  nest role_name
	end
      end

      def has_role role_name
	members.detect do |member|
	  member.name == role_name
	end
      end

      # Include the identifying roles of an EntityType:
      def include_identifiers(exclude_role)
	namespace = self
	while namespace.name == nil
	  namespace = namespace.parent
	end
	# Include the identifying_roles of @object_type
	@object_type.identifying_roles.each do |role|
	  next if role == false   ## WTF? Constraint has an identifying_role of "false"
	  next if (exclude_role == role.counterpart)	# Skip implicit source role
	  next if namespace.has_role role.name

	  # REVISIT: Skip if this role has already been absorbed (object_type is a supertype)

#	  puts "#{indent}Including identifying #{role.name}"
	  absorption = Absorption.new(@vocabulary, self, role.name, nil)
	  role = absorption.role || absorption.parent.role
	  absorption.contents role
	end
      end

      def contents(exclude_role = nil, *a, &b)
	include_identifiers exclude_role if @object_type.is_entity_type

	if b
	  old_exclude = @exclude_role
	  @exclude_role = exclude_role
	  instance_exec(&b)
	  @exclude_role = old_exclude
	end
      end

      def indent
	parent ? parent.indent+(name ? '  ' : '..') : ''
      end

      def inspect
	"#{parent ? parent.inspect+'.' : ''}#{object_type ? object_type.basename : '<array>'}"
      end

      def tree
	(
	  [ "#{indent}#{name || (parent ? '(anonymous)' : vocabulary.name)}" ] +
	  members.map do |m|
	    m.tree
	  end
	) * "\n"
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
      object_type = @vocabulary.object_type(sym)
      raise "Object Type #{sym} is not known" unless object_type

      hash = a.last.is_a?(Hash) ? a.pop : {}

      name = hash[:name] || object_type.basename

#      puts "#{indent}Compositing #{object_type.basename} as #{name} with options #{hash.inspect}"
      absorption = Absorption.new(@vocabulary, self, name, object_type, hash)
      absorption.contents(nil, *a, &b)
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

    def inspect
      "#{vocabulary.name}"
    end

    def tree
      "#{vocabulary.name}\n"+
      members.map do |m|
	m.tree
      end * "\n\n"
    end

    def traversals
      []
    end

private
    # Return a hash of every role used in this Composition (as key) with value false
    def unmarked_roles
      vocabulary.object_type.values.inject({}) do |h, o|
	o.all_role_transitive.map do |k,v|
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
