module Miam
  class InlinePolicy < Model
    attribute :name, :string
    attribute :statements
    attribute :updated_at, :datetime, default: -> { Time.now.utc }

    validates :name, presence: true

    def self.from_dynamo_record(item)
      new(
        name: item['name'],
        statements: item['statements'].map do |stmt|
          Miam::PolicyStatement.from_dynamo_record(stmt)
        end,
        updated_at: Time.at(item['updated_at'].to_i)
      )
    end

    def statements=(arg)
      super(arg.select do |item|
        item.is_a?(Miam::PolicyStatement)
      end)
    end
  end
end
