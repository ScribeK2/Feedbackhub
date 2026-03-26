module Admin
  class TemplatesController < ApplicationController
    before_action :set_template, only: %i[edit update destroy]

    def index
      @templates = FeedbackTemplate.all
      render Admin::TemplateListComponent.new(templates: @templates)
    end

    def new
      @template = FeedbackTemplate.new
      render Admin::TemplateFormComponent.new(template: @template)
    end

    def create
      @template = FeedbackTemplate.new(template_params)

      if @template.save
        redirect_to admin_templates_path, notice: "Template created successfully!"
      else
        render Admin::TemplateFormComponent.new(template: @template), status: :unprocessable_entity
      end
    end

    def edit
      render Admin::TemplateFormComponent.new(template: @template)
    end

    def update
      if @template.update(template_params)
        redirect_to admin_templates_path, notice: "Template updated successfully!"
      else
        render Admin::TemplateFormComponent.new(template: @template), status: :unprocessable_entity
      end
    end

    def destroy
      @template.destroy
      redirect_to admin_templates_path, notice: "Template deleted successfully!"
    end

    private

    def set_template
      @template = FeedbackTemplate.find(params[:id])
    end

    def template_params
      params.require(:feedback_template).permit(:name).tap do |permitted|
        if params[:feedback_template][:field_schema].present?
          permitted[:field_schema] = JSON.parse(params[:feedback_template][:field_schema])
        end
      end
    rescue JSON::ParserError
      params.require(:feedback_template).permit(:name, :field_schema)
    end
  end
end
