# frozen_string_literal: true

# Base class for all Phlex views (not components)
# Used by the phlex_scaffold generator
module Views
  class Base < ApplicationComponent
    include Phlex::Rails::Helpers::CSRF

    if Rails.env.development?
      def before_template
        comment { "Begin #{self.class.name}" }
        super
      end
    end
  end
end
