module Miam
  class Operation
    attr_reader :context

    OperationError = Class.new(StandardError) do
      attr_reader :data

      def initialize(message, data = nil)
        super(message)
        @data = data
      end
    end

    Output = Class.new(OpenStruct) do
      def as_json
        to_h.as_json
      end

      def to_json(opts = nil)
        to_h.transform_values(&:as_json).to_json
      end
    end

    def self.call(args)
      new.call(args)
    end

    def initialize(context = nil)
      @context = context || {}
    end

    def call(args)
      raise "#call not implemented in #{self.class}"
    end
  end
end
