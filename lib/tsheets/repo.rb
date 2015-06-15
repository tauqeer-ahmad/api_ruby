class TSheets::Repo

  @@allowed_classes_for_spec = {
    boolean: [ TrueClass, FalseClass ],
    integer: [ Fixnum ],
    string:  [ String, Symbol ],
    date:    [ Date, DateTime ],
    datetime: [ DateTime ]
  }

  def initialize(bridge)
    @_bridge = bridge
  end

  def filters
    @@filters
  end

  def where(options)
    @_bridge.get self.model, self.url, self.validated_options(options)
  end

  def validated_options(options)
    -> {
      options.each do |name, value|
        validate_option name, value
      end
    }.call && options
  end

  def validate_option(name, value)
    type_spec = @@filters[name]
    raise ArgumentError, "Unknown filter for #{self.class} - #{name}" if type_spec.nil?
    if type_spec.is_a?(Array)
      if !value.is_a?(Array)
        raise ArgumentError, "Expected the value for the #{name} filter to be an array"
      else
        if value.any? { |v| !self.matches_type_spec?(v.class, type_spec.first) }
          raise ArgumentError, "Expected all values of an array for the #{name} filter to match the type spec: :#{type_spec.first}"
        end
      end
    else
      if !self.matches_type_spec?(value.class, type_spec)
        raise ArgumentError, "Expected the value for the #{name} filter to match the type spec: :#{type_spec}"
      end
    end
  end

  def matches_type_spec?(klass, single_type_spec)
    arr = @@allowed_classes_for_spec[single_type_spec]
    arr ? arr.include?(klass) : TSheets::Helpers.to_class(single_type_spec) == klass
  end

  class << self
    def url address
      define_method :url do
        address
      end
    end

    def model klass
      define_method :model do
        klass
      end
    end

    def actions *list
      define_method :actions do
        list
      end
    end

    def filter fname, type
      @@filters ||= {}
      @@filters[fname] = type
    end

    def inherited(child)
      @@_descendants ||= []
      @@_descendants.push child
    end

    def classes
      @@_descendants
    end
  end
end
