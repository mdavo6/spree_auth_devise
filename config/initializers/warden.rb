# Merges users orders to their account after sign in and sign up.
Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
  if auth.cookies.signed[:guest_token].present?
    if user.is_a?(Spree::User)
      orders_as_guest = Spree::Order.where(email: user.email, guest_token: auth.cookies.signed[:guest_token], user_id: nil)
      if orders_as_guest.any?
        most_recent_order = orders_as_guest.order('updated_at DESC').first
        user.associate_address!(most_recent_order)
      end
      orders_as_guest.each do |order|
        order.associate_user!(user)
      end
    end
  end
end

Warden::Manager.before_logout do |user, auth, opts|
  auth.cookies.delete :guest_token
end
