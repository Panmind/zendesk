require 'digest/md5'

module PM
  # Zendesk remote authentication helper for Rails. Implements JS generation,
  # controller actions and route helpers. Have a look at the code, because it
  # is more explanatory than a thousand words :-)
  #
  # Kudos to the Zendesk staff for such a simple and effective interface.
  #
  # (C) 2010 Mind2Mind.is, spinned off from http://panmind.org/ - MIT License.
  #
  #   - vjt  Fri May 28 14:45:27 CEST 2010
  #
  module Zendesk
    Token      = 'The-Zendesk-Auth-Token-Scrubbed-For-This-Release'.force_utf8.freeze
    Hostname   = 'panmind.zendesk.com'.freeze
    AuthURL    = "http://#{Hostname}/access/remote/".freeze
    ReturnURL  = "http://#{Hostname}/login".freeze
    SupportURL = "http://#{Hostname}/home".freeze

    module Helpers
      def zendesk_tags
        return unless PM::Zendesk.enabled?

        %(<script type="text/javascript">
          var zenbox_params = {
            tab_id:    'feedback',
            tab_color: 'black',
            title:     'Panmind',
            text:      "How may we help you? Please fill in details below, and we'll get back to you as soon as possible.",
            tag:       'feedback',
            url:       '#{Hostname}',
            email:     '#{current_user.email rescue nil}'
          };
        </script>
        <style type='text/css'>@import url('//assets0.zendesk.com/external/zenbox/overlay.css');</style>
        <script type='text/javascript' src='//assets0.zendesk.com/external/zenbox/overlay.js'></script>)
      end

      def zendesk_link_to(text, options = {})
        return unless PM::Zendesk.enabled?
        link_to text, support_path, options
      end
    end

    module Controller
      def self.included(base)
        base.before_filter :zendesk_handle_guests, :only => :zendesk_login
      end

      def zendesk_login
        now   = params[:timestamp] || Time.now.to_i.to_s
        name  = current_user.name.force_utf8
        email = current_user.email.force_utf8
        hash  = Digest::MD5.hexdigest(name + email + Token + now)
        back  = params[:return_to] || ReturnURL

        auth_params = [
          '?name='      + CGI.escape(name),
          '&email='     + CGI.escape(email),
          '&timestamp=' + now,
          '&hash='      + hash,
          '&return_to=' + back
        ].join.force_utf8

        redirect_to(AuthURL + auth_params)
      end

      def zendesk_logout
        flash[:notice] = "Thanks for visiting our support forum."
        redirect_to root_url
      end

      private
        def zendesk_handle_guests
          return if current_user

          if params[:timestamp] && params[:return_to]
            # User clicked on Zendesk "login", thus redirect to our
            # login page, that'll redirect him/her back to Zendesk.
            #
            redirect_to ssl_login_url(:return_to => support_url)
          else
            # User clicked on our "support" link, and maybe doesn't
            # have an account yet: redirect him/her to the support.
            #
            redirect_to SupportURL
          end
        end
    end

    module Routes
      def zendesk(base, options)
        return unless PM::Zendesk.enabled?

        self.support base,           :controller => options[:controller], :action => :zendesk_login
        self.connect "#{base}/exit", :controller => options[:controller], :action => :zendesk_logout
      end
    end

    def self.enabled?
      Rails.env.production?
    end

  end
end

ActionController::Routing::RouteSet::Mapper.send :include, PM::Zendesk::Routes
