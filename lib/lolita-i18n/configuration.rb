module Lolita
  module I18n
    class Configuration

      attr_accessor :yaml_backend

      def load_rails!
        if Lolita.rails3?
          require 'lolita-i18n/rails'
        end
      end 
      # Rerturn existing store or create new Redis connection without any arguments.
      def store
        unless @store
          warn "Lolita::I18n No store specified. See Lolita::I18n"
          @store = Redis.new
        end
        @store
      end

      # Set current store to new Redis connection with given Hash options or accept Redis connection itself.
      def store=(possible_store)
        @store = if possible_store.is_a?(Hash)
           Redis.new(possible_store)
         else
           possible_store
         end
        @store
      end

      # Lazy create new KeyValue backend with current store.
      def backend
        @backend ||= ::I18n::Backend::KeyValue.new(self.store)
      end

      # Load translation from yaml.
      def load_translations
        self.yaml_backend.load_translations
      end

      # Create chain where new KeyValue backend is first and Yaml backend is second.
      def initialize_chain
        ::I18n::Backend::Chain.new(self.backend, self.yaml_backend)
      end

      # Add modules for SimpleBackend that is used for Yaml translations
      def include_modules
        ::I18n::Backend::Simple.send(:include, ::I18n::Backend::Flatten)
        ::I18n::Backend::Simple.send(:include, ::I18n::Backend::Pluralization)
        ::I18n::Backend::Simple.send(:include, ::I18n::Backend::Metadata)
        ::I18n::Backend::Simple.send(:include, ::I18n::Backend::InterpolationCompiler)
      end
    end

  end
end