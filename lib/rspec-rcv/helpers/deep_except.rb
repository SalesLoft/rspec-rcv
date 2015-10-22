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
        if hash.is_a?(Array)
          hash.each_with_index do |item, index|
            hash[index] = inject(item, except)
          end
        end

        return hash unless hash.is_a?(Hash)

        hash.inject({}) do |h, (k, v)|
          if v && v.is_a?(Hash)
            h[k] = inject(v, except) unless except.include?(k.to_sym)
          elsif v && v.is_a?(Array)
            v.each_with_index do |item, index|
              v[index] = inject(item, except)
            end
            h[k] = v unless except.include?(k.to_sym)
          elsif !except.include?(k.to_sym)
            h[k] = v
          end
          h
        end
      end
    end
  end
end

