function ComputeDurations( self )
% self.ComputeDurations()
%
% Compute durations for each keybinds

kbevents = cell( length(self.Header) , 2 );

% Take out T_start and T_stop from Data

T_start_idx = strcmp( self.Data(:,1) , 'StartTime' );
T_stop_idx = strcmp( self.Data(:,1) , 'StopTime' );

data = self.Data( ~( T_start_idx + T_stop_idx ) , : );

% Create list for each KeyBind

[ unique_kb , ~ ,  idx ] = unique_stable(self.Data(:,1)); % Filter each Kb

% Re-order each input to be coherent with Header order
input_found = nan(size(unique_kb));
for c = 1:length(unique_kb)
    
    input_idx  = strcmp(self.Header,unique_kb(c));
    input_idx  = find(input_idx);
    
    input_found(c) = input_idx;
    
end

kbevents(:,1) = self.Header; % Name of KeyBind

count = 0;

for c = 1:length(unique_kb)
    
    count = count + 1;
    
    kbevents{ input_found(count) , 2 } = data( idx == c , [4 3] ); % Time & Up/Down of Keybind
    
end

% Compute the difference between each time
for e = 1 : size( kbevents , 1 )
    
    if size( kbevents{e,2} , 1 ) > 1
        
        time = cell2mat( kbevents {e,2} (:,1) );                       % Get the times
        kbevents {e,2} ( 1:end-1 , end+1 ) = num2cell( diff( time ) ); % Compute the differences
        
    end
    
end

self.KbEvents = kbevents;

end % function
