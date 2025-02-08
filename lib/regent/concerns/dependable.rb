# frozen_string_literal: true

module Regent
  module Concerns
    module Dependable
      class VersionError < StandardError; end

      def self.included(base)
        base.class_eval do
          class << self
            def depends_on(gem_name)
              @dependency = gem_name
            end

            def dependency
              @dependency
            end
          end
        end
      end

      def initialize(**options)
        @dependency = self.class.dependency
        require_dynamic(dependency) if dependency

        super()
      rescue Gem::LoadError
        Regent::Logger.warn_and_exit dependency_warning(dependency, model)
      end

      def require_dynamic(*names)
        names.each { |name| load_dependency(name) }
      end

      private

      attr_reader :dependency

      def load_dependency(name)
        gem(name)
        gem_spec = Gem::Specification.find_by_name(name)

        if defined?(Bundler)
          gem_requirement = dependencies.find { |gem| gem.name == gem_spec.name }.requirement

          unless gem_requirement.satisfied_by?(gem_spec.version)
            raise VersionError, version_error(gem_spec, gem_requirement)
          end
        end

        require_gem(gem_spec)
      end

      def version_error(gem_spec, gem_requirement)
        "'#{gem_spec.name}' gem version is #{gem_spec.version}, but your Gemfile specified #{gem_requirement}."
      end

      def require_gem(gem_spec)
        gem_spec.full_require_paths.each do |path|
          Dir.glob("#{path}/*.rb").each { |file| require file }
        end
      end

      def dependencies
        Bundler.load.dependencies
      end

      def dependency_warning(dependency, model)
        "\n\e[33mIn order to use \e[33;1m#{model}\e[0m\e[33m model you need to install \e[33;1m#{dependency}\e[0m\e[33m gem. Please add \e[33;1mgem \"#{dependency}\"\e[0m\e[33m to your Gemfile.\e[0m"
      end
    end
  end
end
