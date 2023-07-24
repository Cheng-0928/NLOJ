# == Schema Information
#
# Table name: problems
#
#  id                     :bigint           not null, primary key
#  name                   :string(255)
#  description            :text(16777215)
#  source                 :text(16777215)
#  created_at             :datetime
#  updated_at             :datetime
#  input                  :text(16777215)
#  output                 :text(16777215)
#  hint                   :text(16777215)
#  visible_state          :integer          default("public")
#  sjcode                 :text(4294967295)
#  interlib               :text(4294967295)
#  specjudge_type         :integer          not null
#  interlib_type          :integer          not null
#  specjudge_compiler_id  :bigint
#  discussion_visibility  :integer          default("enabled")
#  interlib_impl          :text(4294967295)
#  score_precision        :integer          default(2)
#  verdict_ignore_td_list :string(255)      not null
#  num_stages             :integer          default(1)
#  judge_between_stages   :boolean          default(FALSE)
#  default_scoring_args   :string(255)
#  strict_mode            :boolean          default(FALSE)
#  skip_group             :boolean          default(FALSE)
#  ranklist_display_score :boolean          default(FALSE)
#  code_length_limit      :integer          default(5000000)
#
# Indexes
#
#  index_problems_on_name                   (name)
#  index_problems_on_specjudge_compiler_id  (specjudge_compiler_id)
#  index_problems_on_visible_state          (visible_state)
#
# Foreign Keys
#
#  fk_rails_...  (specjudge_compiler_id => compilers.id)
#

require 'test_helper'

class ProblemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
