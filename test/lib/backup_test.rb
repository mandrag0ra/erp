# encoding: UTF-8
require 'test_helper'

class BackupTest < Test::Unit::TestCase

  def test_backup_and_restore
    file = Ekylibre::Backup.create(:with_prints => true, :author => "Test system")
    assert Ekylibre::Backup.restore(file)
  end

end