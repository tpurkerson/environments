require 'date'
require 'logger'

module Puppet::Parser::Functions
  newfunction(:windows_patch_target_date, :type => :rvalue, :doc => <<-EOS
Determine target date for patching from MSFT 'patch tuesday' offset
args - offset in days, weekday of install 1-7
worst case scenario, first day of month is Wednesday, patch target date may be in next month
must consider current date versus offset target date - ie. the next patch tuesday has not occured
  EOS
  ) do |arguments|
    raise(Puppet::ParseError, "windows_patch_target_date(): Wrong number of arguments, expect 2 - days offset, day of week number " +
        "given (#{arguments.size} for 2)") if arguments.size != 2

    log = Logger.new(STDOUT)
    log.level = Logger::INFO
    
    #these are arguments passed to the function - arg[0] (the first) is offset_days and so on
    offset_days = arguments[0].to_i
    target_day_of_week = arguments[1].to_i
     
    log.info("windows_patch_target_date called: #{offset_days}, #{target_day_of_week}")
    
    #find nth iteration of given day (day specified in 'weekday' variable)
    findnthday = 2
    #Ruby wday number (days are numbered 0-6 beginning with Sunday)
    weekday = 2

    today = Date.parse(Time.now.to_s)
    mydatetime_base = Date.new(today.year, today.month, 1)

    while mydatetime_base.wday != weekday do
      mydatetime_base = mydatetime_base + 1;
    end
    patch_tuesday = mydatetime_base + (7 * (findnthday - 1))

    if mydatetime_base.month == 12
      temp_year = today.year.to_i
      temp_year += 1
      mydatetime_next_month_base = Date.new(temp_year, 1, 1)
    else
      temp_month = today.month.to_i
      temp_month += 1
      mydatetime_next_month_base = Date.new(today.year.to_i, temp_month.to_i, 1)
    end

    while mydatetime_next_month_base.wday != weekday do
      mydatetime_next_month_base = mydatetime_next_month_base + 1;
    end
    patch_tuesday_next_month = mydatetime_next_month_base + (7 * (findnthday - 1))

    next_months_patch_tuesday = Date.new(patch_tuesday_next_month.year.to_i, patch_tuesday_next_month.month.to_i, patch_tuesday_next_month.day.to_i)

    if next_months_patch_tuesday.year.to_i != patch_tuesday.year.to_i
      daycount = 0
      temp_date = patch_tuesday

      while temp_date != next_months_patch_tuesday do
        temp_date += 1
        daycount += 1
      end
      days_next_patch_tuesday = daycount
    else
      days_next_patch_tuesday = next_months_patch_tuesday.yday - patch_tuesday.yday
    end

    raise(Puppet::ParseError, "days offset from patch tuesday out of bounds!, offset too large " +
        "max is (#{days_next_patch_tuesday})") if offset_days > days_next_patch_tuesday

    if patch_tuesday > today

      if today.month.to_i == 1
        lastyear = today.year.to_i - 1
        mydatetime_base = Date.new(lastyear, 12, 1)
      else
        tempInt = -1
        lastmonth = today.month.to_i
        lastmonth += tempInt
        mydatetime_base = Date.new(today.year.to_i, lastmonth, 1)
      end

      while mydatetime_base.wday != weekday do
        mydatetime_base = mydatetime_base + 1;
      end

      patch_tuesday = mydatetime_base + (7 * (findnthday - 1))

      targetDate = patch_tuesday
      targetDate += offset_days

      while targetDate.wday != target_day_of_week
        targetDate += 1
      end

      retval = targetDate.year.to_s + '-' + targetDate.month.to_s.rjust(2, '0') + '-' + targetDate.day.to_s.rjust(2, '0')
      return retval
    end

    targetDate = patch_tuesday
    targetDate += offset_days

    while targetDate.wday != target_day_of_week
      targetDate += 1
    end

    retval = targetDate.year.to_s + '-' + targetDate.month.to_s.rjust(2, '0') + '-' + targetDate.day.to_s.rjust(2, '0')
    return retval

  end
end
