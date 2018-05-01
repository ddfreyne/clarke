# frozen_string_literal: true

module Clarke
  module Util
    module Num2String
      NUM_MAPPING = [
        ('0'..'9'),
        ('a'..'z'),
        ('A'..'Z'),
      ].map(&:to_a).flatten.freeze

      def self.call(num)
        run(num).reverse.scan(/.{1,4}/).join('-').reverse
      end

      def self.run(num)
        q, r = num.divmod(NUM_MAPPING.size)
        (q > 0 ? run(q) : '') + NUM_MAPPING[r]
      end
    end
  end
end
