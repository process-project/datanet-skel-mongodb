class CatchErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue
      puts $!
      puts $!.backtrace
      [
        500, { "Content-Type" => "application/json" },
        [ { message: 'Internal application error, please contact administrator' }.to_json ]
      ]
    end
  end
end
