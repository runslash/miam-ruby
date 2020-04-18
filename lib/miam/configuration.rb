module Miam
  class Configuration
    attr_accessor :concurrency, :environment, :operation_parameter_name

    def initialize(&block)
      self.concurrency = 4
      self.environment = 'development'
      self.operation_parameter_name = 'Operation'
      instance_exec(&block) if block_given?
    end

    def to_h
      {
        concurrency: concurrency,
        environment: environment,
        operation_parameter_name: operation_parameter_name
      }
    end
  end
end
