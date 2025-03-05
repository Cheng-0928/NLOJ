class RanklistUpdateChannel < ApplicationCable::Channel
  def subscribed
    # reject() will return true
    reject && return unless params[:id].is_a? Integer
    reject && return if single_contest && single_contest.id != params[:id]
    contest = Contest.find_by_id(params[:id])
    reject && return unless contest.is_started?
    if !contest.dashboard_during_contest && contest.is_running? && !effective_admin?
      stream_from "ranklist_update_#{contest.id}_#{current_user.id}" if current_user
      stream_from "ranklist_update_#{contest.id}_global"
    else
      stream_from "ranklist_update_#{contest.id}"
    end
  end

  def unsubscribed
  end
end
