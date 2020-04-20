module Miam
  class Policy < Model
    self.table_name = "miam-#{Miam::Application.environment}-policies"

    attribute :account_id, :string
    attribute :name, :string
    attribute :version, :string, default: -> { Time.now.strftime('%Y%m%d%H%M%S') }
    attribute :statements
    attribute :user_names
    attribute :group_names
    attribute :created_at, :datetime, default: -> { Time.now.utc }
    attribute :updated_at, :datetime, default: -> { Time.now.utc }

    validates :name, presence: true

    def self.from_dynamo_record(item)
      new(
        account_id: item['account_id'],
        name: item['name'],
        version: item['version'],
        statements: item['statements'].map do |stmt|
          Miam::PolicyStatement.from_dynamo_record(stmt)
        end,
        user_names: item['user_names'],
        group_names: item['group_names'],
        created_at: Time.at(item['created_at'].to_i),
        updated_at: Time.at(item['updated_at'].to_i)
      )
    end

    def name_version
      "#{name}/#{version}"
    end

    def statements=(arg)
      super(
        arg.map do |item|
          case item
          when Hash then Miam::PolicyStatement.new(item.symbolize_keys)
          when Miam::PolicyStatement then item
          end
        end.compact
      )
    end

    def allow(operation_name, **kwargs)
      matched_stmt = statements.find do |stmt|
        stmt.action.any? { |action| operation_name.match?(/\A#{action}/i) }
      end
      matched_stmt
    end
  end
end
