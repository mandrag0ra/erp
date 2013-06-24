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
# == Table: productions
#
#  activity_id       :integer          not null
#  campaign_id       :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  position          :integer
#  product_nature_id :integer          not null
#  started_at        :datetime
#  state             :string(255)
#  static_storage    :boolean          not null
#  stopped_at        :datetime
#  storage_id        :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class Production < Ekylibre::Record::Base
  attr_accessible :activity_id, :product_nature_id, :area_unit, :work_unit
  belongs_to :activity
  # belongs_to :area_unit, :class_name => "Unit"
  belongs_to :product_nature
  # belongs_to :work_unit, :class_name => "Unit"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :state, :allow_nil => true, :maximum => 255
  validates_inclusion_of :static_storage, :in => [true, false]
  validates_presence_of :activity, :product_nature
  #]VALIDATORS]
end