module Miam
  class PolicyStatement < Model
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

    private

    def effect_validator
      return if EFFECTS.include?(effect)

      errors.add(:effect, 'incorrect_value', allowed_values: EFFECTS)
    end
  end
end
