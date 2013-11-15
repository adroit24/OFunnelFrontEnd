class BraintreeController < ApplicationController
  before_filter :check_current_user
  layout "relationships"

  def upgrade

  end

  def create_subscription
    card_holder_name = params[:card_holder_name]
    card_number = params[:number]
    cvv = params[:cvv]
    expiration_month = params[:month]
    expiration_year = params[:year]

    create_subscription_api_endpoint = "#{Settings.api_endpoints.CreateSubscriptionForAlerts}"
    response = Typhoeus.post(
        create_subscription_api_endpoint,
        body: {
            userId: current_user_id,
            cardHolderName: card_holder_name,
            cardNumber: card_number,
            cvvNumber: cvv,
            expirationMonth: expiration_month,
            expirationYear: expiration_year
        })

    if response.success? && !api_contains_error("CreateSubscriptionForAlerts", response)
      response = JSON.parse(response.response_body)["CreateSubscriptionForAlertsResult"]
      status = response["isSubscriptionCreated"]
    else
      flash[:notice] = JSON.parse(response.response_body)["CreateSubscriptionForAlertsResult"]["error"]["errorMessage"]
    end
    if status
      redirect_to notifications_path
    else
      redirect_to upgrade_path
    end
  end

  def delete_card
    "deleteCreditCard"
    delete_card_api_endpoint = "#{Settings.api_endpoints.DeleteCreditCard}"
    response = Typhoeus.post(
        delete_card_api_endpoint,
        body: {
            userId: current_user_id
        })
    status = false
    if response.success? && !api_contains_error("DeleteCreditCard", response)
      response = JSON.parse(response.response_body)["DeleteCreditCardResult"]
      status = response["isCreditCardDeleted"]
    end
    unless status
      flash[:notice] = "Error occurred, please try again."
    end
    redirect_to notifications_path
  end

  def update_card_info
    card_holder_name = params[:card_holder_name]
    card_number = params[:number]
    cvv = params[:cvv]
    expiration_month = params[:month]
    expiration_year = params[:year]

    update_card_info_api_endpoint = "#{Settings.api_endpoints.ChangeCreditCardForSubscription}"
    response = Typhoeus.post(
        update_card_info_api_endpoint,
        body: {
            userId: current_user_id,
            cardHolderName: card_holder_name,
            cardNumber: card_number,
            cvvNumber: cvv,
            expirationMonth: expiration_month,
            expirationYear: expiration_year
        })
    status = false
    if response.success? && !api_contains_error("ChangeCreditCardForSubscription", response)
      response = JSON.parse(response.response_body)["ChangeCreditCardForSubscriptionResult"]
      status = response["isCreatedCardChanged"]
    end
    if status
      redirect_to notifications_path
    else
      flash[:notice] = "Error occurred, please try again."
      redirect_to notifications_path
    end
  end

  def cancel_subscription
    create_subscription_api_endpoint = "#{Settings.api_endpoints.CancelSubscriptionForAlerts}"
    response = Typhoeus.post(
        create_subscription_api_endpoint,
        body: {
            userId: current_user_id,
        })

    status = false
    if response.success? && !api_contains_error("CancelSubscriptionForAlerts", response)
      response = JSON.parse(response.response_body)["CancelSubscriptionForAlertsResult"]
      status = response["isSubscriptionCanceled"]
    end
    if status
      redirect_to notifications_path
    else
      flash[:notice] = "Error occurred, please try again."
      redirect_to notifications_path
    end
  end

end
