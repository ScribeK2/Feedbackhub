# frozen_string_literal: true

require "test_helper"

class Admin::TemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @template = feedback_templates(:simple_template)
  end

  test "index lists all templates" do
    get admin_templates_path
    assert_response :success
  end

  test "new renders template form" do
    get new_admin_template_path
    assert_response :success
  end

  test "create saves valid template" do
    assert_difference "FeedbackTemplate.count", 1 do
      post admin_templates_path, params: {
        feedback_template: {
          name: "Brand New Template",
          field_schema: '[{"name": "test", "label": "Test", "type": "string", "required": true}]'
        }
      }
    end
    assert_redirected_to admin_templates_path
    follow_redirect!
    assert_response :success
  end

  test "create with invalid params re-renders form" do
    assert_no_difference "FeedbackTemplate.count" do
      post admin_templates_path, params: {
        feedback_template: { name: "", field_schema: "[]" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create with duplicate name re-renders form" do
    existing = feedback_templates(:csr_feedback)
    assert_no_difference "FeedbackTemplate.count" do
      post admin_templates_path, params: {
        feedback_template: {
          name: existing.name,
          field_schema: '[{"name": "f", "label": "F", "type": "string"}]'
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create with invalid JSON handles error gracefully" do
    assert_no_difference "FeedbackTemplate.count" do
      post admin_templates_path, params: {
        feedback_template: { name: "Bad JSON", field_schema: "not json at all" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit renders template form" do
    get edit_admin_template_path(@template)
    assert_response :success
  end

  test "update modifies template" do
    patch admin_template_path(@template), params: {
      feedback_template: {
        name: "Updated Name",
        field_schema: JSON.generate(@template.field_schema)
      }
    }
    assert_redirected_to admin_templates_path
    @template.reload
    assert_equal "Updated Name", @template.name
  end

  test "update with invalid params re-renders form" do
    patch admin_template_path(@template), params: {
      feedback_template: { name: "" }
    }
    assert_response :unprocessable_entity
  end

  test "destroy deletes template" do
    assert_difference "FeedbackTemplate.count", -1 do
      delete admin_template_path(@template)
    end
    assert_redirected_to admin_templates_path
  end
end
