require 'panmind/zendesk'

ActionView::Base.instance_eval { include Panmind::Zendesk::Helpers }
ActionController::Routing::RouteSet::Mapper.instance_eval { include Panmind::Zendesk::Routes }
