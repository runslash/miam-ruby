module Miam
  module AuthenticationHandlers
    class MiamAccessKeyV1 < Miam::AuthenticationHandler
      DIGEST = OpenSSL::Digest.new('sha256')

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
        return if access_key.expired?

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
          owner = find_owner(access_key)
          owner_type = owner.is_a?(Miam::Role) ? 'role' : 'user'
          policies = Miam::PolicyService.instance.mfind(
            owner.account_id, find_policy_names(owner)
          )
          Miam::CacheStore.put(
            "#{owner.account_id}/#{access_key.owner_type}=#{access_key.owner_name}/policies",
            policies.as_json
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

        return if matched_policy.nil?

        AuthResult.new(
          access_key.account_id, access_key.owner_type, access_key.owner_name,
          matched_policy.name, matched_policy_statement
        )
      end

      private

      def signature_for(secret, date, body_signature_sha1, headers = {})
        decoded_secret = Base64.decode64(secret)
        k_date = OpenSSL::HMAC.digest(DIGEST, decoded_secret, date.to_s)
        k_headers = OpenSSL::HMAC.digest(
          DIGEST, k_date,
          headers.collect { |key, value| "#{key}=#{value}" }.join(';')
        )
        k_signing = OpenSSL::HMAC.digest(DIGEST, k_headers, 'miam_ak_v1')
        OpenSSL::HMAC.hexdigest(DIGEST, k_signing, body_signature_sha1)
      end

      def find_owner(access_key)
        if !access_key.user_name.nil?
          Miam::UserService.instance.find(
            access_key.account_id, access_key.user_name
          )
        else
          Miam::RoleService.instance.find(
            access_key.account_id, access_key.role_name
          )
        end
      end

      def find_policy_names(owner)
        owner_groups = Miam::GroupService.instance.mfind(
          owner.account_id, owner.group_names.to_a
        )
        policy_names = (owner.policy_names || []).to_a
        policy_names.concat(
          (owner_groups || []).flat_map { |group| group.policy_names.to_a }
        )
      end
    end
  end
end
