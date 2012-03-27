module IrcParser
  @@registered_commands = {}

  # Returns a Command class and processed arguments for it.
  def self.parse(raw_data)
    return [nil, []] if raw_data.nil?

    command, args = parse_line(raw_data)

    [@@registered_commands[command], args]
  end

  def self.register_command(command, klass)
    @@registered_commands[command.to_s] = klass
  end

  protected

  def self.parse_line(raw_data)
    data = raw_data.chomp.split(' ').compact
    return [nil, []] if data.size == 0

    # Ignore optional userhost field when present.
    if data.first.start_with? ':'
      data.shift
    end

    command = data.shift

    # Convert "someargument :Other long argument" to ["someargument", "Other long argument"]
    slices = data.slice_before { |word| word.start_with?(':') }.to_a

    args = if slices.size == 1
      join_long_argument(slices.first)
    elsif slices.size == 0
      []
    else
      slices.shift + join_long_argument(slices.flatten)
    end

    [command, args]
  end

  def self.join_long_argument(arg)
    if arg.is_a?(Array) && arg.first && arg.first.start_with?(':')
      arg.first.sub!(':', '')
      [arg.join(' ')]
    else
      arg
    end
  end
end
