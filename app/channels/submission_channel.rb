class SubmissionChannel < ApplicationCable::Channel
  def subscribed
    # reject() will return true
    if params[:id].is_a? Integer
      submission = Submission.find_by_id(params[:id])
      reject && return if single_contest && submission.contest_id != single_contest.id
      reject && return unless submission&.allowed_for(current_user, effective_admin?)
      with_detail = submission&.tasks_allowed_for(current_user, effective_admin?)
      stream_from "submission_#{submission.id}_subtasks"
      stream_from "submission_#{submission.id}_testdata" if with_detail
      stream_from "submission_#{submission.id}_overall"
      init_data(submission, with_detail)
    else
      reject && return if params[:id].size > 20
      submissions = Submission.where(id: params[:id])
      submissions = submissions.where(contest_id: single_contest.id) if single_contest
      submissions = submissions.filter{|s| s.allowed_for(current_user, effective_admin?)}
      reject && return if not submissions
      submissions.each do |s|
        stream_from "submission_#{s.id}_overall"
        init_data(s, false, true)
      end
    end
  end

  def unsubscribed
  end

  private

  def init_data(submission, with_detail, overall_only = false)
    unless overall_only
      ActionCable.server.broadcast("submission_#{submission.id}_subtasks", {subtask_scores: submission.get_subtask_result})
      ActionCable.server.broadcast("submission_#{submission.id}_testdata", {
        testdata: submission.submission_testdata_results.map do |t|
          [:position, :result, :time, :rss, :vss, :score, :message_type, :message].map{|attr|
            [attr, t.read_attribute(attr)]
          }.to_h
        end
      }) if with_detail
    end
    ActionCable.server.broadcast("submission_#{submission.id}_overall", [:id, :score, :result, :total_time, :total_memory, :message].map{|attr|
      [attr, submission.read_attribute(attr)]
    }.to_h)
  end
end
