# frozen_string_literal: true

# This generator allows Phlex to be used as a template engine for scaffolds
# when configured in config/application.rb with:
#   config.generators.template_engine :phlex_scaffold

module PhlexScaffold
  module Generators
    class ScaffoldGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :attributes, type: :array, default: [], banner: "field[:type][:index] field[:type][:index]"

      def create_views
        %w[index show new edit].each do |view|
          @view_name = view
          template "#{view}.rb.erb", File.join("app/views", class_path, plural_file_name, "#{view}.rb")
        end

        # Create the form partial
        @view_name = "form"
        template "_form.rb.erb", File.join("app/views", class_path, plural_file_name, "_form.rb")
      end

      def create_controller
        template "controller.rb.erb", File.join("app/controllers", class_path, "#{controller_file_name}_controller.rb")
      end

      private

      def model_name
        @model_name ||= class_name.classify
      end

      def plural_table_name
        @plural_table_name ||= model_name.tableize
      end

      def singular_table_name
        @singular_table_name ||= model_name.tableize.singularize
      end

      def instance_name
        "@#{singular_table_name}"
      end

      def plural_instance_name
        "@#{plural_table_name}"
      end

      def attributes_list
        return [] if attributes.empty?

        attributes.map do |attr|
          { name: attr.name, type: attr.type.to_s }
        end
      end

      def display_attributes
        return [ { name: "name", type: "string" } ] if attributes_list.empty?

        # Filter out timestamps and id
        attributes_list.reject { |attr| %w[id created_at updated_at].include?(attr[:name]) }
      end

      def form_attributes
        display_attributes
      end

      def controller_class_name
        model_name.pluralize
      end

      def controller_file_name
        plural_file_name
      end

      def orm_class
        ::Rails::Generators::ActiveModel
      end

      def permitted_params
        attributes_names.map { |name| ":#{name}" }.join(", ")
      end

      def attributes_names
        attributes.map { |attr| attr.name }
      end

      def redirect_resource_name
        if namespaced?
          "[:#{namespace}, @#{singular_table_name}]"
        else
          "@#{singular_table_name}"
        end
      end

      def index_helper
        if namespaced?
          "#{namespace}_#{plural_table_name}"
        else
          plural_table_name
        end
      end

      def human_name
        class_name.humanize
      end

      def plural_param_name
        plural_table_name
      end

      def param_name
        singular_table_name
      end
    end
  end
end
