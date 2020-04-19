module Miam
  module AuthenticationHandlers
    class MiamAccessKeyV1 < Miam::AuthenticationHandler
      def initialize(token)
        @token = token
      end

      def allow!(operation_name, body_signature_sha1, **kwargs)
        token_split = @token.split('; ')
        token_data = token_split.each_with_object({}) do |item, hash|
          item_split = item.split('=')
          hash[item_split.shift] = item_split.join('=')
        end
        return if token_data['credentials'].nil?

        access_key, secret_access_key = \
          Miam::AccessKeyService.instance.find_with_secret(
            token_data['credentials']
          )
        return if secret_access_key.nil?

        signed_headers = token_data['signed_headers'].to_s.split(',')
        expected_signature = signature_for(
          secret_access_key, token_data['date'], body_signature_sha1,
          kwargs.fetch(:headers, {}).slice(*signed_headers)
        )
        return unless token_data['signature'] == expected_signature

        cached_policies = Miam::CacheService.instance.get(
          "#{access_key.account_id}/user=#{access_key.user_name}/policies"
        )
        policies = []
        if !cached_policies.nil?
          policies = cached_policies.map do |item|
            Miam::Policy.from_dynamo_record(item)
          end
        else
          user = Miam::UserService.instance.find(
            access_key.account_id, access_key.user_name
          )
          user_groups = Miam::GroupService.instance.mfind(
            access_key.account_id, user.group_names.to_a
          )
          policy_names = (user.policy_names || []).to_a
          policy_names.concat(
            (user_groups || []).flat_map { |group| group.policy_names.to_a }
          )
          policies = Miam::PolicyService.instance.mfind(
            access_key.account_id, policy_names
          )
          Miam::CacheService.instance.put(
            "#{user.account_id}/user=#{user.name}/policies", policies.as_json
          )
        end
        pp policies.as_json
        [Miam::Policy.new, Miam::PolicyStatement.new]
      end

      private

      def signature_for(secret, date, body_signature_sha1, headers = {})
        decoded_secret = Base64.decode64(secret)
        k_date = OpenSSL::HMAC.digest('SHA256', decoded_secret, date.to_s)
        k_headers = OpenSSL::HMAC.digest(
          'SHA256', k_date,
          headers.collect { |key, value| "#{key}=#{value}" }.join(';')
        )
        k_signing = OpenSSL::HMAC.digest('SHA256', k_headers, 'miam_ak_v1')
        OpenSSL::HMAC.hexdigest('SHA256', k_signing, body_signature_sha1)
      end
    end
  end
end
