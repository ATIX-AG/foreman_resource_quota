# frozen_string_literal: true

module ForemanResourceQuota
  module Async
    class RefreshResourceQuotaUtilization < ::Actions::EntryAction
      include ::Actions::RecurringAction

      def run
        ResourceQuota.all.each do |quota|
          quota.determine_utilization
        rescue e
          logger.error N_(format("An error occured determining the utilization of '%s'-quota: %s", quota.name, e))
        end
      end

      def logger
        action_logger
      end

      def rescue_strategy_for_self
        Dynflow::Action::Rescue::Fail
      end
    end
  end
end
