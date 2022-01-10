class StaffRole < ApplicationRecord
  audited

  def taikai_admin?
    code == 'taikai_admin'
  end

  def dojo_admin?
    code == 'dojo_admin'
  end

  def marking_referee?
    code == 'marking_referee'
  end

  def yatori?
    code == 'yatori'
  end
end
