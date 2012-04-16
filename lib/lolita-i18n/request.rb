require "json"

module Lolita
  module I18n
    class Request

      class Validator

        def validate(key,value)
          if value.is_a?(Array)
            validate_array(key,value)
          elsif value.is_a?(Hash)
            validate_hash(key,value)
          else
            validate_value(key,value)
          end
        end

        private

        def validate_array(key,values)
          translation = Translation.new(key,values)
          if translation.original.class != values.class || translation.original.size != values.size
            raise Exceptions::TranslationDoesNotMatch.new(values,translation.original) 
          end
          values.each_with_index do |value,index|
            validate_value(key,value,:index => index)
          end
        end

        def validate_hash(key,hash)
          translation = Translation.new(key,hash)
          if translation.original.class != hash.class || (hash.keys.map(&:to_sym) - translation.original.keys).any?
            raise Exceptions::TranslationDoesNotMatch.new(hash,translation.original) 
          end
          hash.each do |hash_key,value|
            validate_value(key,value, :key => hash_key)
          end
        end

        def validate_value(key,value, options = {})
          value = value.to_s 
          original_value = current_value_for_original(key,value,options)
          unless interpolations(value) == interpolations(original_value)
            raise Exceptions::MissingInterpolationArgument.new(interpolations(original_value))
          end
        end

        def current_value_for_original(key,value,options = {})
          translation = Translation.new(key,value)
          original = translation.original
          if original.is_a?(Hash)
            original[options[:key].to_sym]
          elsif original.is_a?(Array)
            original[options[:index].to_i]
          else
            original
          end
        end

        def interpolations(value)
          value.to_s.scan(/(%{\w+})/).map{|m| m.first}.sort
        end
      end

      class Translation

        def initialize(key,translation)
          @key,@translation = key, translation
          @key_parts = @key.to_s.split(".")
        end

        def value
          Yajl::Parser.parse(@translation.to_json)
        end

        def locale
          (locale_from_key || ::I18n.default_locale).to_sym
        end

        def for_store
          [locale, { key => value }, :escape => false]
        end

        def key
          @key_parts[1..-1].join(".")
        end

        def original
          @original ||= ::I18n.t(self.key, :locale => ::I18n.default_locale)
        end

        private

        def locale_from_key
          @key_parts.first
        end

      end

      class Translations
        def initialize(translations_hash)
          @translations = translations_hash
        end

        def normalized(locale)
          unless @normalized
            @normalized = {}
            flatten_keys(@translations,locale) do |key,value,original_value|
              @normalized[key] = {:translation => value, :original_translation => original_value}
            end
          end
          @normalized
        end

        def flatten_keys hash,locale, prev_key = nil, &block
          hash.each_pair do |key,value|
            current_key = [prev_key, key].compact.join(".").to_sym
            if final_value?(value)
              yield current_key, translation_value(current_key,value,locale), value
            else
              flatten_keys(value,locale,current_key, &block)
            end
          end
        end

        def final_value?(value)
          !value.is_a?(Hash) || 
          (value.is_a?(Hash) && value.keys.include?(:other) && value.keys.size > 1 && !value.values.detect{|value| value.is_a?(Array) || value.is_a?(Hash)}) 
        end

        def translation_value key, value, locale
          translation_value = ::I18n.t(key,:locale => locale, :default => "")
          translation_value = {} if value.is_a?(Hash) && !translation_value.is_a?(Hash)
          translation_value = [] if value.is_a?(Array) && !translation_value.is_a?(Array)
          translation_value
        end
      end

      attr_accessor :params

      def initialize(params)
        self.params = params
      end

      def translations locale
        Lolita.i18n.load_translations
        translations = Translations.new(Lolita.i18n.yaml_backend.send(:translations)[::I18n.default_locale]) 
        translations.normalized(locale)
      end

      def update_key
        set(Base64.decode64(params[:id]),params[:translation])
      end

      def validator
        @validator ||= Validator.new()
      end

      def del key
        Lolita.i18n.store.del key
      end

      private 
      
      def set(key,translation)
        translation = Translation.new(key,translation)
        if translation.value.blank?
          self.delete_key(key)
        else
          validator.validate(key,translation.value)
          !!Lolita.i18n.backend.store_translations(*translation.for_store)
        end
      end

    end
  end
end