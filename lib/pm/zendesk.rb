require 'digest/md5'
require 'pm/string_force_utf8_patch' # TODO rework

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
    class ConfigurationError < StandardError; end

    class << self
      attr_reader :token, :hostname

      def auth_url;    @auth_url    ||= "http://#{hostname}/access/remote/".freeze end
      def return_url;  @return_url  ||= "http://#{hostname}/login".freeze          end
      def support_url; @support_url ||= "http://#{hostname}/home".freeze           end

      attr_accessor :dropbox, :login, :assets_path, :assets_name

      def set(options)
        self.token, self.hostname, self.login = options.values_at(:token, :hostname, :login)

        if self.token.blank? || self.hostname.blank? || self.login.blank?
          raise ConfigurationError, "Zendesk requires the API token, an hostname and a proc to infer the user name and e-mail"
        end

        self.dropbox = (options[:dropbox] || {}).reverse_merge(
          :tab_id    => 'feedback',
          :tab_color => 'black',
          :title     => 'Support',
          :text      => "How may we help you? Please fill in details below, and we'll get back to you as soon as possible.",
          :url       => Zendesk.hostname
        ).freeze

        # TODO better configuration
        self.assets_path = options[:assets_path] || '//assets0.zendesk.com/external/zenbox'
        self.assets_name = options[:assets_name] || 'overlay'
      end

      def enabled?
        Rails.env.production?
      end

      private
        def token=(token);       @token    = token.force_utf8.freeze end
        def hostname=(hostname); @hostname = hostname.freeze         end
    end

    module Helpers
      def zendesk_dropbox_config
        config = Zendesk.dropbox
        if config[:email].kind_of?(Proc)
          config = config.merge(:email => instance_exec(&config[:email]))
        end

        javascript_tag("var zenbox_params = #{config.to_json};").html_safe
      end

      def zendesk_dropbox_tags
        return unless Zendesk.enabled?

        %(#{zendesk_dropbox_config}
        <style type='text/css'>@import url('#{Zendesk.assets_path}/#{Zendesk.assets_name}.css');</style>
        <script type='text/javascript' src='#{Zendesk.assets_path}/#{Zendesk.assets_name}.js'></script>).html_safe
      end

      def zendesk_link_to(text, options = {})
        return unless Zendesk.enabled?
        link_to text, support_path, options
      end

      def zendesk_dropbox_link_to(text)
        link_to text, '#', :onclick => 'Zenbox.render (); return false'
      end
    end

    module Controller
      def self.included(base)
        base.before_filter :zendesk_handle_guests, :only => :zendesk_login
      end

      def zendesk_login
        name, email = instance_exec(&Zendesk.login).map!(&:force_utf8)

        now  = params[:timestamp] || Time.now.to_i.to_s
        hash = Digest::MD5.hexdigest(name + email + Zendesk.token + now)
        back = params[:return_to] || Zendesk.return_url

        auth_params = [
          '?name='      + CGI.escape(name),
          '&email='     + CGI.escape(email),
          '&timestamp=' + now,
          '&hash='      + hash,
          '&return_to=' + back
        ].join.force_utf8

        redirect_to(Zendesk.auth_url + auth_params)
      end

      def zendesk_logout
        flash[:notice] = "Thanks for visiting our support forum."
        redirect_to root_url
      end

      private
        def zendesk_handle_guests
          return if logged_in? rescue false # TODO add another option

          if params[:timestamp] && params[:return_to]
            # User clicked on Zendesk "login", thus redirect to our
            # login page, that'll redirect him/her back to Zendesk.
            #
            redirect_to ssl_login_url(:return_to => support_url)
          else
            # User clicked on our "support" link, and maybe doesn't
            # have an account yet: redirect him/her to the support.
            #
            redirect_to Zendesk.support_url
          end
        end
    end

    module Routes
      def zendesk(base, options)
        return unless Zendesk.enabled?

        self.support base,           :controller => options[:controller], :action => :zendesk_login
        self.connect "#{base}/exit", :controller => options[:controller], :action => :zendesk_logout
      end
    end

  end
end

ActionController::Routing::RouteSet::Mapper.send :include, PM::Zendesk::Routes
