module Promotions
    class PromotionService

        def self.list_vouchers()
            MyAppTracer.in_span("list vouchers from external services") do |span|
                # random sleep from 100ms to 500ms
                s = (rand(100...500).to_f/1000).to_f # divide by 1000 to get millisecond

                Rails.logger.debug "PromotionService.list_vouchers call started"
                sleep(s)
                Rails.logger.debug "PromotionService.list_vouchers done"

                return [
                    [
                        'voucher_code' => 'REGISTER_ANNIVERSARY',
                        'description' => 'will get 5% discount if user is a loyal users (already joined minimum 1 year)',
                        'terms_and_conditions': [
                            'discount' => 5,
                            'min_registered_year' => 1,
                            'registered_date_is_same' => true,
                            'registered_month_is_same' => true,
                            'name_prefix' => "",
                        ]
                    ],
                    [
                        'voucher_code' => 'I_AM_JAN',
                        'description' => "will get 1% discount if user have name prefix 'jan' because our app is launched at January!",
                        'terms_and_conditions': [
                            'discount' => 1,
                            'min_registered_year' => 0,
                            'registered_date_is_same' => false,
                            'registered_month_is_same' => false,
                            'name_prefix' => "",
                        ]
                    ]
                ]
            end
        end
    end
end