module ContestsHelper
  def contest_type_desc_map
    {
      "ioi" => "IOI style (rank by score)",
      "ioi_new" => "New IOI style (rank by score, union by subtasks)",
      "acm" => "ACM style (rank by solved problems)",
      "ioicamp" => "ioicamp style (rank by score, then penalty)",
    }
  end

  def contest_type_short_desc_map
    {
      "ioi" => "IOI style",
      "ioi_new" => "New IOI style",
      "acm" => "ACM style",
      "ioicamp" => "IOICamp style",
    }
  end

  def register_mode_desc_map
    {
      "no_register" => "No registration required",
      "free_register" => "Registration required, no approval needed",
      "require_approval" => "Registration and approval required",
    }
  end

  def rel_timestamp(submission, start_time)
    submission.created_at_usec - to_us(start_time)
  end

  # return item_state
  def acm_ranklist_state(submission, start_time, item_state, is_waiting)
    # state: [attempts, ac_usec, is_first_ac, waiting]
    if item_state.nil?
      item_state = [0, nil, 0]
    end
    return nil if not item_state[1].nil?
    item_state = item_state.dup
    if is_waiting
      item_state[2] += 1
    else
      item_state[0] += 1
      if submission.result == 'AC'
        item_state[1] = rel_timestamp(submission, start_time)
        item_state[2] = 0
      end
    end
    item_state
  end

  def ioi_ranklist_state(submission, start_time, item_state, is_waiting)
    # state: [score, has_sub, waiting]
    if item_state.nil?
      item_state = [BigDecimal(0), false, 0]
    end
    if is_waiting
      item_state = item_state.dup
      item_state[2] += 1
      item_state
    else
      item_state[0] >= submission.score && item_state[1] ? nil : [submission.score, true, item_state[2]]
    end
  end

  def ioi_new_ranklist_state(submission, start_time, item_state, is_waiting)
    # state: [score, has_sub, waiting]
    if item_state.nil?
      item_state = [BigDecimal(0), false, 0, nil]
    end
    item_state = item_state.dup
    if is_waiting
      item_state[2] += 1
      item_state
    else
      scores = submission.get_subtask_result.map{|x| x[:score]}
      if item_state[3].nil?
        item_state[3] = scores
      else
        item_state[3] = item_state[3].zip(scores).map(&:max)
      end
      nscore = item_state[3].sum
      item_state[0] >= nscore && item_state[1] ? nil : [nscore, true, item_state[2], item_state[3]]
    end
  end

  def ioicamp_ranklist_state(submission, start_time, item_state, is_waiting)
    # state: [score, waiting, penalty_attempts, last_update_usec, attempts_after_last_update]
    if item_state.nil?
      item_state = [BigDecimal(0), 0, 0, nil, 0, nil]
    end
    item_state = item_state.dup
    if is_waiting
      item_state[1] += 1
    else
      item_state[4] += 1

      scores = submission.get_subtask_result.map{|x| x[:score]}
      if item_state[5].nil?
        item_state[5] = scores
      else
        item_state[5] = item_state[5].zip(scores).map(&:max)
      end
      nscore = item_state[5].sum

      if nscore > item_state[0]
        item_state[0] = nscore
        item_state[2] += item_state[4] - 1
        item_state[4] = 1
        item_state[3] = rel_timestamp(submission, start_time)
      end
    end
    item_state
  end

  def ranklist_data(submissions, start_time, freeze_start, rule)
    res = Hash.new { |h, k| h[k] = [] }
    participants = Set[]
    func = {
      'acm' => method(:acm_ranklist_state),
      'ioi' => method(:ioi_ranklist_state),
      'ioi_new' => method(:ioi_new_ranklist_state),
      'ioicamp' => method(:ioicamp_ranklist_state),
    }[rule]
    first_ac = {}
    submissions = submissions.to_a
    submissions.each do |sub|
      participants << sub.user_id
      next if ['CE', 'ER', 'CLE', 'JE'].include?(sub.result) && sub.created_at < freeze_start
      key = "#{sub.user_id}_#{sub.problem_id}"
      is_waiting = ['queued', 'received', 'Validating'].include?(sub.result) || sub.created_at >= freeze_start
      orig_state = res[key][-1]&.dig(:state)
      new_state = func.call(sub, start_time, orig_state, is_waiting)
      res[key] << {timestamp: rel_timestamp(sub, start_time), state: new_state, submission_id: sub.id} unless new_state.nil?
      first_ac[sub.problem_id] = first_ac.fetch(sub.problem_id, sub.user_id) if sub.result == 'AC' && sub.created_at < freeze_start
    end
    res.delete_if { |key, value| value.empty? }
    res.each_value {|x| x.each {|item| item[:state].pop}} if ['ioi_new', 'ioicamp'].include? rule
    {result: res, participants: participants.to_a, first_ac: first_ac}
  end

  def problem_index_text(index)
    text = ''
    while index >= 26
      text = (65 + index % 26).chr + text
      index = index / 26 - 1
    end
    return 'p' + (65 + index % 26).chr + text
  end
end
