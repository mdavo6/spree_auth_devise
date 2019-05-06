module Spree
  class User < Spree::Base
    include UserAddress
    include UserPaymentSource

    devise :database_authenticatable, :registerable, :recoverable,
           :rememberable, :trackable, :validatable, :encryptable, :encryptor => 'authlogic_sha512'
    devise :confirmable if Spree::Auth::Config[:confirmable]

    acts_as_paranoid
    after_destroy :scramble_email_and_password

    has_many :orders

    before_validation :set_login

    users_table_name = User.table_name
    roles_table_name = Role.table_name

    scope :admin, -> { includes(:spree_roles).where("#{roles_table_name}.name" => "admin") }

    def self.admin_created?
      User.admin.count > 0
    end

    def admin?
      has_spree_role?('admin')
    end

    def associate_address!(order)
      self.bill_address ||= order.bill_address
      self.ship_address ||= order.ship_address

      changes = slice(:bill_address_id, :ship_address_id)

      self.class.unscoped.where(id: self).update_all(changes)
    end

    protected
      def password_required?
        !persisted? || password.present? || password_confirmation.present?
      end

    private

      def set_login
        # for now force login to be same as email, eventually we will make this configurable, etc.
        self.login ||= self.email if self.email
      end

      def scramble_email_and_password
        self.email = SecureRandom.uuid + "@example.net"
        self.login = self.email
        self.password = SecureRandom.hex(8)
        self.password_confirmation = self.password
        self.save
      end
  end
end
