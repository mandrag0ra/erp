# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: budget_items
#
#  budget_id             :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  currency              :string(255)      not null
#  global_amount         :decimal(19, 4)   default(0.0), not null
#  id                    :integer          not null, primary key
#  lock_version          :integer          default(0), not null
#  production_support_id :integer          not null
#  quantity              :decimal(19, 4)   default(0.0), not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#
class BudgetItem < Ekylibre::Record::Base
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :global_amount, :quantity, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 255
  validates_presence_of :budget, :currency, :global_amount, :production_support, :quantity
  #]VALIDATORS]
  validates_uniqueness_of :production_support_id, scope: :budget_id

  belongs_to :budget, inverse_of: :items
  belongs_to :production_support

  delegate :computation_method, to: :budget

  enumerize :currency, in: Nomen::Currencies.all, default: Preference[:currency]

  before_validation do
    quantity = 1 if computation_method == :per_production_support
  end

  validate do
    global_amount = budget.unit_amount * quantity
  end
end
