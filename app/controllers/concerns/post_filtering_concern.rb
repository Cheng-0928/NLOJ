module PostFilteringConcern
  extend ActiveSupport::Concern

 private

  def check_contest_and_problem
    unless effective_admin?
      if not @contest and Contest.where("start_time <= ? AND ? < end_time AND disable_discussion", Time.now, Time.now).exists?
        redirect_back fallback_location: root_path, notice: "No discussion during contest."
        return
      end
      if @problem and @problem.discussion_disabled?
        redirect_to problem_path(@problem), alert: "Discussion not allowed in this problem."
        return
      end
    end
  end

  def check_problem_allow_create
    unless effective_admin?
      if @problem and not @problem.discussion_enabled?
        redirect_to problem_posts_path(@problem), alert: "Discussion not allowed in this problem."
        return
      end
    end
  end

  def filter_posts
    @problem = Problem.find(params[:problem_id]) if params[:problem_id] and not @contest
    if @contest
      @posts = @contest.posts.order(global_visible: :desc) # put announcements on top
      @postable = @contest
      @page_path = helpers.contest_adaptive_polymorphic_path([:posts], strip_prefix: false)
    elsif @problem
      @posts = @problem.posts.order(Arel.sql("(post_type = #{Post.post_types[:solution]}) DESC"))
      @postable = @problem
      @page_path = problem_posts_path(@problem)
    else
      @posts = Post.where(postable_type: nil).or(Post.where(postable_type: 'Problem', post_type: :issue))
      @postable = nil
      @page_path = posts_path
    end
    if user_signed_in?
      unless effective_admin?
        # cannot use .or here because it will OR on the whole clause
        @posts = @posts.where('user_id = ? OR global_visible', current_user.id)
      end
    else
      @posts = @posts.where(global_visible: true)
    end
  end
end
