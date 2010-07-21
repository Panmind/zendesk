require 'panmind/zendesk'
require 'panmind/string_force_utf8_patch'

ActionView::Base.instance_eval { include Panmind::Zendesk::Helpers }
ActionController::Routing::RouteSet::Mapper.instance_eval { include Panmind::Zendesk::Routes }
