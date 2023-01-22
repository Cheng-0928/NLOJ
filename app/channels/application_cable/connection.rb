module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :judge_server, :current_user
    
    def initialize(*args)
      super
      @mutex = Mutex.new
    end

    def connect
      if request.params['key']
        @mutex.synchronize do
          return if @disconnected
          judge_server = find_judge_server
          judge_server.with_lock do
            reject_unauthorized_connection if judge_server.online
            judge_server.update(online: true)
          end
          self.judge_server = judge_server
        end
      else
        self.current_user = find_user
      end
    end

    def disconnect
      # connect and disconnect may be called in different thread simutaneously, thus use a mutex to prevent races
      @mutex.synchronize do
        if self.judge_server
          self.judge_server.update(online: false)
        end
        @disconnected = true
      end
    end

    private

    def find_judge_server
      key = request.params['key']
      reject_unauthorized_connection if not key
      judge = JudgeServer.find_by(key: key)
      reject_unauthorized_connection if not judge or (not (judge.ip || "").empty? and judge.ip != request.remote_ip)
      judge
    end

    def find_user
      user_id = cookies.encrypted[:_tioj_session]&.dig('warden.user.user.key', 0, 0)
      reject_unauthorized_connection if not user_id
      user = User.find(user_id)
      reject_unauthorized_connection if not user
      user
    end
  end
end
