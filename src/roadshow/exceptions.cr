module Roadshow
  class UnknownCommand < Exception
  end

  class InvalidArgument < Exception
  end

  class CommandFailed < Exception
  end

  class InvalidConfig < Exception
  end
end
