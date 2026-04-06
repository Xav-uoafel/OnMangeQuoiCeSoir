class Household < ApplicationRecord
  has_many :users

  validates :invite_code, presence: true, uniqueness: true
  validates :name, presence: true

  before_validation :generate_invite_code, on: :create

  def admin
    users.find_by(household_role: 'admin')
  end

  def members
    users.where(household_role: 'member')
  end

  def all_pantry_items
    PantryItem.where(user_id: users.pluck(:id))
  end

  private

  def generate_invite_code
    self.invite_code ||= SecureRandom.alphanumeric(8).upcase
  end
end
