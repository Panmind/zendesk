require 'panmind/zendesk'

module Panmind
  module Zendesk

    if defined? Rails::Railtie
      class Railtie < Rails::Railtie
        initializer 'panmind.zendesk.insert_into_action_view' do
          ActiveSupport.on_load :action_view do
            Panmind::Zendesk::Railtie.insert
          end
        end
      end
    end

    class Railtie
      def self.insert
        ActionView::Base.instance_eval { include Panmind::Zendesk::Helpers }
        ActionDispatch::Routing::Mapper.instance_eval { include Panmind::Zendesk::Routing }
      end
    end

  end
end
