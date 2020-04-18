module Miam
  class Model
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::AttributeMethods
    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations

    def self.table_name=(name)
      @table_name = name.to_s
    end

    def self.table_name
      @table_name
    end

    def as_output
      as_json
    end
  end
end
