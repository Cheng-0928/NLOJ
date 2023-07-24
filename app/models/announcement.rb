# == Schema Information
#
# Table name: announcements
#
#  id         :bigint           not null, primary key
#  title      :string(255)
#  body       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  contest_id :bigint
#
# Indexes
#
#  index_announcements_on_contest_id  (contest_id)
#
# Foreign Keys
#
#  fk_rails_...  (contest_id => contests.id)
#
class Announcement < ApplicationRecord
  belongs_to :contest, optional: true
end
