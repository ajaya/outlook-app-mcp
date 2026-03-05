# frozen_string_literal: true

module OutlookMcp
  module Graph
    module SanitizeIds
      ID_PATTERN = /\A[a-zA-Z0-9\-_=.]+\z/
      ID_PARAMS = %i[id folder_id message_id attachment_id destination_folder_id parent_folder_id].to_set.freeze

      def self.sanitize!(id)
        raise ArgumentError, "Invalid ID: #{id.inspect}" unless id.is_a?(String) && id.match?(ID_PATTERN)

        id
      end

      # Builds a module that wraps every method in +mod+ whose signature
      # contains a known ID parameter, sanitizing the value before calling super.
      def self.wrap(mod)
        Module.new do
          mod.instance_methods(false).each do |method_name|
            params = mod.instance_method(method_name).parameters
            id_indices = []
            id_keywords = []

            params.each_with_index do |(type, name), idx|
              next unless ID_PARAMS.include?(name)

              case type
              when :req, :opt then id_indices << idx
              when :key, :keyreq then id_keywords << name
              end
            end

            next if id_indices.empty? && id_keywords.empty?

            define_method(method_name) do |*args, **kwargs, &block|
              id_indices.each { |i| SanitizeIds.sanitize!(args[i]) if args[i] }
              id_keywords.each { |k| SanitizeIds.sanitize!(kwargs[k]) if kwargs[k] }
              super(*args, **kwargs, &block)
            end
          end
        end
      end
    end
  end
end
