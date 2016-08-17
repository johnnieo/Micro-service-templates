class LogFormatter < Logger::Formatter
  def call(severity, _time, _progname, msg)
    format("[%s:%s] %s\n", severity[0], Thread.current.object_id.to_s(16), msg)
  end
end
