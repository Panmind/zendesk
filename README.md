Zendesk on Rails - Dropbox and Remote Authentication
====================================================

Purpose
-------

The plugin implements the HTML generation code for the
[Zendesk dropbox](http://www.zendesk.com/blog/instant-support-access-with-drop-box)
and the necessary controller and routing code to implement
[Zendesk's remote authentication](http://www.zendesk.com/api/remote-authentication)


Installation
------------

    script/plugin install git://github.com/Panmind/zendesk.git

Gems will follow soon, hopefully after the July 22nd Ruby Social Club in Milan.


Configuration
-------------

In your `config/routes.rb`:

    map.zendesk '/support', :controller => 'sessions'

The `/support` path will then respond to the methods that generate the query
string parameters required for Remote Authentication, while the `/support/exit`
path will simply set a notice in the flash and redirect the user to the app
`root_url`. You can override this behaviour by implementing a `zendesk_logout`
method in the controller.

You can define these methods in any of your controllers, in this example we
defined it in the `SessionsController`: so, in your `sessions_controller.rb`:

    include Panmind::Zendesk::Controller if Panmind::Zendesk.enabled?

Finally, in your config/environment.rb:

    Panmind::Zendesk.set(
      :token     => 'Your Zendesk token',
      :hostname  => 'example.zendesk.com',
      :login     => proc { [current_user.name, current_user.email] },
      :login_url => :login_url,
      :dropbox   => {
        :title => 'Dropbox title',
        :email => proc { current_user.email rescue nil }
      }
    )

The required options are:

 * `:token`     - your zendesk [shared secret](http://www.zendesk.com/api/remote-authentication)
 * `:hostname`  - your zendesk account host name
 * `:login`     - a `Proc` object evaluated in the controller instance context,
                  that must return an `Array` whose first element is the current
                  user name and the second its email. This `Proc` is evaluated
                  iff the `logged_in?` instance method of your controller returns
                  true. Configuration of the method name will follow.
 * `:login_url` - The name of the named route helper that generates the full URL
                  of your user login page. We use `:ssl_login_url` thanks to our
                  [SSL Helper](http://github.com/Panmind/ssl_helper) plugin.

The `:dropbox` option is for the [Zendesk dropbox](http://www.zendesk.com/blog/instant-support-access-with-drop-box)
configuration, it should be an hash with symbolized keys and it is converted to
`JSON` and bound to the `zendesk_params` Javascript variable.

To facilitate the Dropbox usage, the `:email` option can be a `Proc` object that
is then evaluated in the controller instance context and should return the current
user e-mail or nil if the user is not logged in. If the `:email` option is unset
no e-mail appears precompiled in the Dropbox for, or you could even set a static
email for every feedback request (dunno why should you do that, though :-).


Usage
-----

To embed the Dropbox tags, use the `zendesk_dropbox_tags` helper
in your layout:

    <%= zendesk_dropbox_tags %>

To display a link that displays the dropbox when clicked use the
`zendesk_dropbox_link_to` helper in your views:

    <%= zendesk_dropbox_link_to 'Send feedback' %>

To display a link that starts the Remote Authentication process
use the `zendesk_link_to` helper in your views:

    <%= zendesk_link_to 'Support' %>

The second parameter of said helper is passed to Rails' `link_to`
one to customize the link tag attributes.


To-do
-----

 * Clean up configuration by requiring less information: *convention over configuration*!
 * Configuration of the `logged_in?` method name: not everyone still uses RESTful authentication nowadays
 * Removal of the `String#force_utf8` patch and its usage in the plugin
 * Code documentation
 * Allow options passing to the `zendesk_dropbox_link_to` helper
 * Tests

Please fork the project and send us a pull request if you check off any of these items
from the to-do list, or for any other improvement. Thanks! :-)

