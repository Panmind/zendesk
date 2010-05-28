require 'digest/md5'

module PM
  module Zendesk
    Token      = 'The-Zendesk-Auth-Token-Scrubbed-For-This-Release'.force_utf8.freeze
    Hostname   = 'panmind.zendesk.com'.freeze
    RemoteAuth = "http://#{Hostname}/access/remote/".freeze
    NormalAuth = "http://#{Hostname}/access/normal/".freeze
    ZendeskURL = "http://#{Hostname}/login".freeze

    module Helpers
      def zendesk_tags
        #return unless Rails.env.production?

        %(<script type="text/javascript">
          var zenbox_params = {
            tab_id:    'feedback',
            tab_color: 'black',
            title:     'Panmind',
            text:      "How may we help you? Please fill in details below, and we'll get back to you as soon as possible.",
            tag:       'feedback',
            url:       'panmind.zendesk.com',
            email:     '#{current_user.email rescue nil}'
          };
        </script>
        <style type='text/css'>@import url('//assets0.zendesk.com/external/zenbox/overlay.css');</style>
        <script type='text/javascript' src='//assets0.zendesk.com/external/zenbox/overlay.js'></script>)
      end
    end

    module Controller
      def zendesk_login
        redirect_to NormalAuth and return unless current_user

        now   = params[:timestamp] || Time.now.to_i.to_s
        name  = current_user.name.force_utf8
        email = current_user.email.force_utf8
        hash  = Digest::MD5.hexdigest(name + email + Token + now)
        back  = params[:return_to] || ZendeskURL

        auth_params = [
          '?name='      + CGI.escape(name),
          '&email='     + CGI.escape(email),
          '&timestamp=' + now,
          '&hash='      + hash,
          '&return_to=' + back
        ].join.force_utf8

        redirect_to(RemoteAuth + auth_params)
      end

      def zendesk_logout
        flash[:notice] = "Thanks for visiting our support forum."
        redirect_to root_url
      end
    end

    module Routes
      def zendesk(base, options)
        self.support base,           :controller => options[:controller], :action => :zendesk_login
        self.connect "#{base}/exit", :controller => options[:controller], :action => :zendesk_logout
      end
    end

  end
end

ActionController::Routing::RouteSet::Mapper.send :include, PM::Zendesk::Routes
