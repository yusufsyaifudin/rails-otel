require 'opentelemetry/sdk'

module Vouchers
    class UserVoucher

       def self.vouchers(user_id)
           MyAppTracer.in_span("list voucher business logic") do |span|

               Rails.logger.debug "reaching business logic"
               Rails.logger.debug "doing query get user by id #{user_id}"
               user = User::find_by(:id => user_id)

               throw :NotFoundUser if user.nil?

               Rails.logger.debug_ctx(
                "calling PromotionService.list_vouchers from UserVoucher.list_vouchers",
                nil,
                {username: user.username},
               )

               vouchers = Promotions::PromotionService::list_vouchers()

               return {
                   'user' => user,
                   'vouchers' => vouchers
               }
           end
       end

    end
end