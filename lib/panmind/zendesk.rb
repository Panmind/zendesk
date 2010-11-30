require 'digest/md5'
require 'panmind/zendesk/railtie' if defined? Rails

module Panmind
  # Zendesk remote authentication helper for Rails. Implements JS generation,
  # controller actions and route helpers. Have a look at the code, because it
  # is more explanatory than a thousand words :-)
  #
  # Kudos to the Zendesk staff for such a simple and effective interface.
  #
  # (C) 2010 Panmind, Released under the terms of the Ruby License.
  #
  #   - vjt  Wed Jul 21 13:00:42 CEST 2010
  #
  module Zendesk
    Version = '1.0.2'

    class ConfigurationError < StandardError; end

    class << self
      attr_reader :token, :hostname

      def auth_url;    @auth_url    ||= "http://#{hostname}/access/remote/".freeze end
      def return_url;  @return_url  ||= "http://#{hostname}/login".freeze          end
      def support_url; @support_url ||= "http://#{hostname}/home".freeze           end

      # TODO these should become attr_readers and we set @variables directly
      attr_accessor :dropbox, :login, :login_url, :js_asset_path, :js_asset_name, :css_asset_path, :css_asset_name 

      def set(options)
        self.token, self.hostname, self.login, self.login_url =
          options.values_at(:token, :hostname, :login, :login_url)

        if %w( token hostname login login_url ).any? {|conf| send(conf).blank?}
          raise ConfigurationError, "Zendesk requires the API token, an hostname a proc to infer the user name "\
                                    "and e-mail and the login route helper name" # TODO don't require all these things
        end

        if options[:dropbox].nil? or options[:dropbox][:dropboxID].blank? 
          raise ConfigurationError, "DropboxID is a required param in zenbox-2.0. Please configure options[:dropbox][:dropboxID]."
        end 

        # Dropbox specific customizations, defaults in place
        self.dropbox = (options[:dropbox] || {}).reverse_merge(
          :tabID       => 'feedback',
          :url         => Zendesk.hostname
        ).freeze

        # Path and name for css and asset required for zenbox 2.0
        self.js_asset_path  = options[:js_asset_path]  || '//assets0.zendesk.com/external/zenbox'
        self.js_asset_name  = options[:js_asset_name]  || 'zenbox-2.0'
        self.css_asset_path = options[:css_asset_path] || '//assets0.zendesk.com/external/zenbox'
        self.css_asset_name = options[:css_asset_name] || 'zenbox-2.0'
      end

      def enabled?
        Rails.env.production? || Rails.env.development? 
      end

      private
        def token=(token);       @token    = token.freeze    rescue nil end
        def hostname=(hostname); @hostname = hostname.freeze            end
    end

    module Helpers
      def zendesk_dropbox_config
        config = Zendesk.dropbox

        [:requester_email, :requester_name].each do |key| 
          config = config.merge(key => instance_exec(&config[key])) if config[key].kind_of?(Proc)
        end

        javascript_tag("var zenbox_params = #{config.to_json};").html_safe
      end

      def zendesk_dropbox_tags
        return unless Zendesk.enabled?
        
        %(#{zendesk_dropbox_config}
        <style type='text/css' media='screen,projection'>@import url('#{Zendesk.css_asset_path}/#{Zendesk.css_asset_name}.css');</style>
        <script type='text/javascript' src='#{Zendesk.js_asset_path}/#{Zendesk.js_asset_name}.js'></script>).html_safe
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
        name, email = instance_exec(&Zendesk.login)

        now  = params[:timestamp] || Time.now.to_i.to_s
        hash = Digest::MD5.hexdigest(name + email + Zendesk.token + now)
        back = params[:return_to] || Zendesk.return_url

        auth_params = [
          '?name='      + CGI.escape(name),
          '&email='     + CGI.escape(email),
          '&timestamp=' + now,
          '&hash='      + hash,
          '&return_to=' + back
        ].join

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
            redirect_to send(Zendesk.login_url, :return_to => support_url)
          else
            # User clicked on our "support" link, and maybe doesn't
            # have an account yet: redirect him/her to the support.
            #
            redirect_to Zendesk.support_url
          end
        end
    end

    module Routing
      def zendesk(base, options = {})
        return unless Zendesk.enabled?

        scope base.to_s, :controller => options[:controller] do
          get '',     :action => :zendesk_login,  :as => base.to_sym
          get 'exit', :action => :zendesk_logout, :as => nil
        end
      end
    end

  end
end
