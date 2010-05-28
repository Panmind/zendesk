require 'digest/md5'

module PM
  module Zendesk
    Token      = 'The-Zendesk-Auth-Token-Scrubbed-For-This-Release'.force_utf8.freeze
    Hostname   = 'panmind.zendesk.com'.freeze
    RemoteAuth = "http://#{Hostname}/access/remote/".freeze
    NormalAuth = "http://#{Hostname}/access/normal/".freeze

    module Helpers
      def zendesk_tags
        #return unless Rails.env.production?

        %(<script type="text/javascript">
          var zenbox_params = {
            tab_id:    'feedback',
            tab_color: 'black',
            title:     'Panmind',
            text:      "How may we help you? Please fill in details below, and we'll get back to you as soon as possible.",
            tag:       'dropbox',
            url:       'panmind.zendesk.com',
            email:     '#{current_user.email rescue nil}'
          };
        </script>
        <style type='text/css'>@import url('//assets0.zendesk.com/external/zenbox/overlay.css');</style>
        <script type='text/javascript' src='//assets0.zendesk.com/external/zenbox/overlay.js'></script>)
      end
    end

    module Controller
      def self.included(base)
        base.before_filter :validate_zendesk_redirect, :only => [:zendesk_login, :zendesk_logout]
      end

      def zendesk_login
        now   = Time.now.to_i.to_s.force_utf8
        name  = current_user.name.force_utf8
        email = current_user.email.force_utf8
        hash  = Digest::MD5.hexdigest(name + email + Token + now)
        back  = params[:return_to]

        params =
          '?name='      + CGI.escape(name),
          '&email='     + CGI.escape(email),
          '&timestamp=' + now,
          '&hash='      + hash,
          '&return_to=' + back

        redirect_to(RemoteAuth + params)
      end

      def zendesk_logout
      end

      private
        def validate_zendesk_redirect
          redirect_to NormalAuth unless current_user
        end
    end

    module Routes
      def zendesk(options)
        self.zendesk_login  '/zendesk/login',  :controller => options[:controller], :action => :zendesk_login
        self.zendesk_logout '/zendesk/logout', :controller => options[:controller], :action => :zendesk_logout
      end
    end

  end
end

ActionController::Routing::RouteSet::Mapper.send :include, PM::Zendesk::Routes
