module Miam
  module InlinePolicyAttachable
    def self.included(base)
      base.attribute :inline_policies
    end

    def inline_policies=(arg)
      super(arg.select do |item|
        item.is_a?(Miam::Policy)
      end)
    end
  end
end
