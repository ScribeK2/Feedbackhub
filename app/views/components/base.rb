# frozen_string_literal: true

# Base class for reusable components
# Inherits from ApplicationComponent which includes PhlexyUI and Rails helpers
class Components::Base < ApplicationComponent
  if Rails.env.development?
    def before_template
      comment { "Begin #{self.class.name}" }
      super
    end
  end

  protected

  # Generate a valid HTML id from a form field name
  # e.g., "user[email]" => "user_email"
  def generate_id_from_name(name)
    name.to_s.gsub(/[\[\]]/, "_").gsub(/__+/, "_").chomp("_")
  end

  # Filter out specific keys from attributes hash
  def filtered_attributes(*exclude_keys)
    @attributes.except(*exclude_keys, :class)
  end

  # Combine CSS classes from multiple sources
  def css_classes(*class_arrays)
    [ *class_arrays, (@attributes || {})[:class] ].compact.flatten.join(" ")
  end
end
