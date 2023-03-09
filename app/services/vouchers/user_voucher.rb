module Vouchers
    class UserVoucher

       def self.vouchers(user_id)
           Rails.logger.debug "reaching business logic"
           Rails.logger.debug "doing query get user by id #{user_id}"
           user = User::find_by(:id => user_id)

           throw :NotFoundUser if user.nil?

           Rails.logger.debug "calling PromotionService.list_vouchers from UserVoucher.list_vouchers #{user_id}"
           vouchers = Promotions::PromotionService::list_vouchers()

           return {
               'user' => user,
               'vouchers' => vouchers
           }
       end

    end
end