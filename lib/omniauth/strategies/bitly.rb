require 'omniauth-oauth2'
require 'multi_json'

module OmniAuth
  module Strategies
    class Bitly < OmniAuth::Strategies::OAuth2
      option :name, "bitly"
      option :client_options,{:site => 'https://api-ssl.bitly.com/',
                              :authorize_url => 'https://bitly.com/oauth/authorize',
                              :token_url => 'https://api-ssl.bitly.com/oauth/access_token'}

      option :token_params, {
        :parse => :query
      }

      uid{ access_token.params['login'] }


      info do
        {
          'login' => access_token.params['login'],
          'api_key' => access_token.params['apiKey'],
          'display_name' => raw_info['display_name'],
          'full_name' => raw_info['full_name'],
          'profile_image' => raw_info['profile_image'],
          'profile_url'=>raw_info['profile_url']
        }
      end

      extra do
        {:raw_info => raw_info}
      end
      
      def raw_info
        # HACK HACK HACK
        access_token.options[:mode] = :query
        access_token.options[:param_name] = :access_token
        @raw_info ||= MultiJson.decode(access_token.get('/v3/user/info').body)
      end

      def callback_phase
        request.params["state"] = session["omniauth.state"] unless request.params["state"]
        super
      end

      # Having the code included in the redirect_url when fetching the token
      # causes INVALID_CODE errors from Bitly.
      # see https://github.com/omniauth/omniauth-oauth2/issues/93
      # and https://github.com/isaacsanders/omniauth-stripe-connect/pull/49
      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
OmniAuth.config.add_camelization 'bitly', 'Bitly'
