function AddStopTime( obj, stoptime_name , starttime )
% obj.AddStartTime( StopTime_name = str , StartTime = double )
%
% Add special event { StopTime_name starttime }

if ~ischar( stoptime_name )
    error( 'StopTime_name must be string' )
end

if ~isnumeric( starttime )
    error( 'StopTime must be numeric' )
end

obj.IncreaseEventCount;
obj.Data( obj.EventCount , 1:2 ) = { stoptime_name starttime };
% ex : Add T_stop = 0 on the next line (usually last line)

end
