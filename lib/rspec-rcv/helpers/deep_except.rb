module RSpecRcv
  module Helpers
    class DeepExcept
      def initialize(hash, except)
        @hash = hash
        @except = except
      end

      def to_h
        inject(@hash, @except.map(&:to_sym))
      end

      private

      def inject(hash, except)
        hash.inject({}) do |h, (k, v)|
          if v && v.respond_to?(:to_h)
            h[k] = inject(v, except)
          elsif !except.include?(k.to_sym)
            h[k] = v
          end
          h
        end
      end
    end
  end
end

