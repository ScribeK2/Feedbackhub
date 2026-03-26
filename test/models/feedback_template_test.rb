# frozen_string_literal: true

require "test_helper"

class FeedbackTemplateTest < ActiveSupport::TestCase
  test "valid template saves successfully" do
    template = FeedbackTemplate.new(
      name: "New Template",
      field_schema: [ { "name" => "field", "label" => "Field", "type" => "string", "required" => true } ]
    )
    assert template.save
  end

  test "requires name" do
    template = FeedbackTemplate.new(field_schema: [ { "name" => "field" } ])
    assert_not template.valid?
    assert_includes template.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    existing = feedback_templates(:csr_feedback)
    template = FeedbackTemplate.new(name: existing.name, field_schema: [])
    assert_not template.valid?
    assert_includes template.errors[:name], "has already been taken"
  end

  test "requires field_schema" do
    template = FeedbackTemplate.new(name: "Empty Schema")
    assert_not template.valid?
    assert_includes template.errors[:field_schema], "can't be blank"
  end

  test "has many feedback submissions" do
    template = feedback_templates(:csr_feedback)
    assert_respond_to template, :feedback_submissions
    assert template.feedback_submissions.count >= 1
  end

  test "destroying template destroys associated submissions" do
    template = feedback_templates(:simple_template)
    submission_count = template.feedback_submissions.count

    assert_difference "FeedbackSubmission.count", -submission_count do
      template.destroy
    end
  end

  test "field_schema stores JSON array" do
    template = feedback_templates(:csr_feedback)
    assert_kind_of Array, template.field_schema
    assert template.field_schema.first.key?("name")
  end
end
