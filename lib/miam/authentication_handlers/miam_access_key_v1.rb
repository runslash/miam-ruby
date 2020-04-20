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

        cached_value = Miam::CacheStore.get(
          "access_key=#{token_data['credentials']}"
        )
        if !cached_value.nil?
          access_key = Miam::AccessKey.new(
            cached_value['access_key'].symbolize_keys
          )
          secret_access_key = cached_value['secret']
        else
          access_key, secret_access_key = \
            Miam::AccessKeyService.instance.find_with_secret(
              token_data['credentials']
            )
          return if access_key.nil? || secret_access_key.nil?

          Miam::CacheStore.put(
            "access_key=#{access_key.id}",
            { 'access_key' => access_key.as_json, 'secret' => secret_access_key }
          )
        end

        signed_headers = token_data['signed_headers'].to_s.split(',')
        expected_signature = signature_for(
          secret_access_key, token_data['date'], body_signature_sha1,
          kwargs.fetch(:headers, {}).slice(*signed_headers)
        )
        return unless token_data['signature'] == expected_signature

        cached_policies = Miam::CacheStore.get(
          "#{access_key.account_id}/user=#{access_key.user_name}/policies"
        )
        policies = []
        if !cached_policies.nil?
          policies = cached_policies.map do |item|
            Miam::Policy.new(item.symbolize_keys)
          end
        else
          user = find_user(access_key.account_id, access_key.user_name)
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
          Miam::CacheStore.put(
            "#{user.account_id}/user=#{user.name}/policies", policies.as_json
          )
        end

        matched_policy = nil
        matched_policy_statement = nil
        policies.each do |policy|
          stmt = policy.allow(
            operation_name,
            resource: kwargs.fetch(:resource, nil),
            condition: kwargs.fetch(:condition, nil)
          )
          next if stmt.nil?

          matched_policy = policy
          matched_policy_statement = stmt
          break
        end

        AuthResult.new(
          access_key.account_id, access_key.user_name, matched_policy.name,
          matched_policy_statement
        )
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

      def find_user(account_id, name)
        # user_cached_value = Miam::CacheStore.get(
        #   "#{account_id}/user=#{name}"
        # )
        # if !user_cached_value.nil?
        #   Miam::User.new(user_cached_value.symbolize_keys)
        # else
        #   Miam::UserService.instance.find(account_id, name).tap do |user|
        #     Miam::CacheStore.put("#{account_id}/user=#{name}", user.as_json)
        #   end
        # end
        Miam::UserService.instance.find(account_id, name)
      end
    end
  end
end
