require_dependency "json_web_token"

class UserPromotionController < ApplicationController

  def list_vouchers
    Rails.logger.debug "request accepted by controller"

    begin
      MyAppTracer.in_span("request accepted by controller") do |span|
        token = ""
        auth = request.headers['Authorization']
        if !auth.nil?
          token = auth.split(' ').last
        end
      
        if token.empty?
          Rails.logger.debug "accepting token from query params"
      
          token = request.query_parameters['token']
        else
          Rails.logger.debug "accepting token from headers"
        end
      
        token_extracted = JsonWebToken::decode(token)
        if token_extracted.nil? || token_extracted.to_a.length() <= 0
          return respond_to do |format|
            format.any {render :json => [
              'message' => 'nil extracted token'
            ]}
          end
        end
      
      
        jwt_payload = token_extracted[0]
        if jwt_payload.nil?
          return respond_to do |format|
            format.any {render :json => [
              'message' => 'nil jwt payload'
            ]}
          end
        end
      
        user_id = jwt_payload['user_id']
        if user_id.nil? || user_id.empty?
          return respond_to do |format|
             format.any {render :json => [
               'message' => 'empty user id from jwt payload'
            ]}
          end
        end
      
        out = Vouchers::UserVoucher::vouchers(user_id)
        Rails.logger.debug "controller done processing the request, preparing rendering response"
      
        return respond_to do |format|
          format.any {render :json => out}
        end
      end # end of tracer block
    rescue => err
      return respond_to do |format|
        format.any  {render :json => [
            'message': err
        ]}
      end

    end # end of begin-rescue
  end

end