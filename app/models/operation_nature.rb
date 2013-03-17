# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: operation_natures
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  description    :text
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  name           :string(255)      not null
#  nomen          :string(255)
#  updated_at     :datetime         not null
#  updater_id     :integer
#  working_set_id :integer
#
class OperationNature < Ekylibre::Record::Base
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :nomen, :allow_nil => true, :maximum => 255
  validates_presence_of :name
  #]VALIDATORS]
end