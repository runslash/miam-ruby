module Miam
  class PolicyStatement < Model
    REGEX_CACHE = Miam::CacheStores::LruCacheStore.new

    EFFECT_ALLOW = 'ALLOW'
    EFFECT_DENY = 'DENY'
    EFFECTS = [EFFECT_ALLOW, EFFECT_DENY].freeze

    attribute :id, :string, default: -> { "Stmt#{(Time.now.to_f * 1000.0).to_i}" }
    attribute :action
    attribute :resource
    attribute :effect, :string, default: EFFECT_ALLOW
    attribute :condition

    validates :id, presence: true
    validates :effect, presence: true
    validate :effect_validator

    def self.from_dynamo_record(item)
      new(
        id: item['id'],
        action: item['action'],
        resource: item['resource'],
        effect: item['effect'],
        condition: item['condition']
      )
    end

    def action=(arg)
      super(
        Set.new(
          Array(arg).map(&:to_s).filter_map do |item|
            item if !item.nil? && item.length > 0
          end
        )
      )
    end

    def resource=(arg)
      super(
        Set.new(
          Array(arg).map(&:to_s).filter_map do |item|
            item if !item.nil? && item.length > 0
          end
        )
      )
    end

    def effect=(value)
      super(value.to_s.upcase)
    end

    def allow?
      effect == EFFECT_ALLOW
    end

    def deny?
      effect == EFFECT_DENY
    end

    def match?(operation_name, **kwargs)
      match_action?(operation_name) &&
        match_resource?(kwargs.fetch(:resource, nil))
    end

    private

    def effect_validator
      return if EFFECTS.include?(effect)

      errors.add(:effect, 'incorrect_value', allowed_values: EFFECTS)
    end

    def match_action?(operation_name)
      action.any? do |item|
        operation_name.match?(
          REGEX_CACHE.fetch("action:#{item}") do
            Regexp.new('\A' + item.gsub(/\*/i, '.+') + '\z', 'i')
          end
        )
      end
    end

    def match_resource?(resource_name)
      return true if resource_name.nil?

      resource.any? do |item|
        resource_name.match?(
          REGEX_CACHE.fetch("resource:#{item}") do
            Regexp.new('\A' + item.gsub(/\*/i, '.+') + '\z', 'i')
          end
        )
      end
    end

    def match_condition?(condition_values)
      true
    end
  end
end
