# Bypassing Chatwoot Paywall in Self-Hosted Installations

This document outlines the mechanism Chatwoot uses to gate premium features in self-hosted installations and provides instructions on how to modify the code to enable these features by default.

**Disclaimer:** Modifying the source code might have unintended consequences, could break future updates, and bypasses the intended licensing model. Proceed with caution and understanding.

## Premium Features

The following features are typically gated behind a non-community (paid) plan:

*   `disable_branding`: Remove "Powered by Chatwoot" branding.
*   `audit_logs`: Access detailed logs of account activities.
*   `sla`: Service Level Agreement configuration and monitoring.
*   `captain` / `captain_integration`: AI features (Captain AI).
*   `custom_roles`: Define specific user permission roles beyond standard ones.
*   `custom_branding`: Apply custom logos, names, and URLs across the installation.
*   `agent_capacity`: Limit the number of concurrent chats auto-assigned to agents.

## Paywall Mechanism

The core mechanism involves checking the installation's pricing plan, which is determined by the `ChatwootHub.pricing_plan` method.

1.  **Plan Check:** Code often checks if `ChatwootHub.pricing_plan != 'community'`. This happens in feature definition files (`enterprise/app/helpers/super_admin/features.yml`) and various controllers/services.
2.  **Feature Flags:** Features are also defined with a `premium: true` flag (`config/features.yml`). The `Account#feature_enabled?` method likely implicitly checks the plan status for these flags.
3.  **Reconciliation Service:** A background service (`Internal::ReconcilePlanConfigService`) runs periodically. If it detects the plan is `'community'`, it actively *disables* all known premium features for all accounts in the database.

## How to Bypass the Paywall (Code Modification)

To enable all premium features, you need to make the application believe it's running on a paid plan and prevent the reconciliation service from reverting the changes.

**Method 1 (Recommended): Modify Plan Check & Reconciliation**

1.  **Force Non-Community Plan:**
    *   Edit the file: `lib/chatwoot_hub.rb`
    *   Locate the `self.pricing_plan` method.
    *   Modify it to always return a non-community plan, for example:
        ```ruby
        def self.pricing_plan
          # Original line: InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'community'
          'enterprise' # Or any string other than 'community'
        end
        ```

2.  **Neutralize Reconciliation Service (Optional but Recommended):**
    *   Edit the file: `enterprise/app/services/internal/reconcile_plan_config_service.rb`
    *   Locate the `reconcile_premium_features` method.
    *   Add a `return` statement at the beginning of the method to prevent it from running:
        ```ruby
        def reconcile_premium_features
          return # <--- Add this line to disable the method

          # Original code below:
          # @premium_features ||= YAML.safe_load(File.read("#{config_path}/premium_features.yml")).freeze
          # Account.find_in_batches do |accounts|
          #   accounts.each do |account|
          #     account.disable_features!(*premium_features)
          #   end
          # end
        end
        ```
    *   *Alternatively*, you could comment out the call `reconcile_premium_features` within the `perform` method of the same file.

**Method 2: Modify Feature Definitions (Less Recommended)**

You could edit `config/features.yml` and `enterprise/app/helpers/super_admin/features.yml` to remove `premium: true` flags and replace `enabled: <%= (ChatwootHub.pricing_plan != 'community') %>` with `enabled: true`. However, this is more distributed and might still be affected by the reconciliation service if not disabled.

## After Modifying

After making these code changes, you will need to:

1.  **Restart** your Chatwoot server process(es) for the changes to take effect.
2.  Potentially run `bundle install` if required, although these changes shouldn't affect gems directly.

Remember that these changes might need to be reapplied after updating Chatwoot. 