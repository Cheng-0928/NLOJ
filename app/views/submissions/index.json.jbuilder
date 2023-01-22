json.array!(@submissions) do |submission|
  json.extract! submission, :id, :result, :score, :problem_id
  json.submitter submission.user.username
  json.total_time submission.total_time.to_i
  json.total_memory submission.total_memory.to_i
  json.compiler submission.compiler.name
  json.code_length submission.code.bytesize
  json.created_at submission.created_at.to_s(:clean)
  json.url submission_url(submission, format: :json)
end
