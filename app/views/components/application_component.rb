class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::Flash
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::FormAuthenticityToken
  include PhlexyUI

  delegate :current_user, to: :view_context
end
