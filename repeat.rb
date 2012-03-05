# code borrowed from post by user elliottcable in the following post:
# http://refactormycode.com/codes/323-every-repeat-module


# Used to repeat a block at a given interval, in seconds.
#   Repeat::Every 30 do
#     puts "I will be printed every thirty seconds"
#   end
# Can be told to not abide slow iterations, and continue on according to
# schedule regardless of the state of block-execute iterations:
#   Repeat::Every 4 do
#     sleep 5; puts "I completed after the next block was initiated"
#   end
# Finally, some convenience methods are proffered for working with the seconds:
#   Repeat::Every 2.hours do; end
#   Repeat::Every 3.days do; end
#   Repeat::Every 140.milliseconds do; end
module Repeat
  StretchMarks = { # In seconds
    :millisecond  =>        0.001,
    :centisecond  =>        0.01,
    :second       =>        1.0,
    :minute       =>       59.83617,
    :hour         =>     3590.1702,
    :day          =>   86_164.09,
    :week         =>  603_148.63
  }
  
  class <<self
    def Every period, opts = {}, &action
      begin
        while true
          act = Thread.new &action
          hold = Thread.new { sleep period }
          
          # Strict timekeeping: Takes :strict => tru in the opts, which
          # causes it to ignore slow blocks. Otherwise, it will continue to
          # wait for slow blocks to evaluate before initiating the next block,
          # even if they exceed the allowed iteration time.
          unless opts[:strict]
            [act, hold].map {|t| t.join }
          else
            act.run
            hold.join
          end
        end
      rescue Interrupt
        puts "\n" # Cleanly exit the loop.
      end
    end
  end
  
  module Every
    class <<self
      # Unfortunately, we can't do a metaprogrammy bit of magic here, due to the
      # fact that blocks in 1.8 can't take other blocks as arguments. Hence, you
      # have to do some lambda magic like this to use the singualar syntax:
      #   Repeat::Every.minute(lambda do
      #     puts 'whee'
      #   end)
      ::Repeat::StretchMarks.each do |stretch, period|
      
        define_method stretch do |proc|
          ::Repeat::Every 1.send(stretch.to_s + 's'), &proc
        end
      
      end
    end
  end
  
  class ::Fixnum
    ::Repeat::StretchMarks.each do |stretch, period|
      
      define_method(stretch.to_s + 's') do
        period * self
      end
      
    end
  end
  
end
