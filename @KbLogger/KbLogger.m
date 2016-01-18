classdef KbLogger < EventRecorder
    
    %KBLOGGER Class to handle the the Keybinds Queue from Psychtoolbox
    %(ex : record MRI triggers while other code is executing)
    
    %% Properties
    
    properties
        
        KbList   = []      % double = [ KbName( 'space' ) KbName( '5%' ) ]
        KbEvents = cell(0) % cell( Columns , 2 )
        
    end % properties
    
    %% Methods
    
    methods
        
        % -----------------------------------------------------------------
        %                           Constructor
        % -----------------------------------------------------------------
        function obj = KbLogger( kblist , header )
            % obj = KbLogger( KbList = [ KbName( 'space' ) KbName( '5%' ) ] , Header = cell( 1 , Columns ) )
            
            % ================ Check input argument =======================
            
            % Arguments ?
            if nargin > 0
                
                % --- kblist ----
                if isvector( kblist ) && isnumeric( kblist ) % Check input argument
                    obj.KbList = kblist;
                else
                    error( 'KbList should be a line vector of positive integers' )
                end
                
                % --- header ----
                if isvector( header ) && ...
                        iscell( header ) && ...
                        length( kblist ) == length( header ) % Check input argument
                    if all( cellfun( @isstr , header ) )
                        obj.Header = header;
                    else
                        error( 'Header should be a line cell of strings' )
                    end
                else
                    error( 'Header should be a line cell of strings and same size as KbList' )
                end
                
            else
                % Create empty KbQueueLogger
            end
            
            % ======================= Callback ============================
            
            obj.Description    = mfilename( 'fullpath' );
            obj.TimeStamp      = datestr( now );
            obj.Columns        = 4;
            obj.Data           = cell( obj.NumberOfEvents , obj.Columns );
            obj.KbEvents       = cell( obj.Columns , 2 );
            obj.NumberOfEvents = NaN;
            
        end
        
        % -----------------------------------------------------------------
        %                            GetQueue
        % -----------------------------------------------------------------
        function GetQueue( obj )
            % obj.GetQueue()
            %
            % Fetch the queue and use AddEvent method to fill obj.Data
            % according to the KbList
            
            while KbEventAvail
                [evt, ~] = KbEventGet; % Get all queued keys
                if any( evt.Keycode == obj.KbList )
                    key_idx = evt.Keycode == obj.KbList;
                    obj.AddEvent( { obj.Header{ key_idx } evt.Time evt.Pressed NaN } )
                end
            end
            
        end
        
        % -----------------------------------------------------------------
        %                        ComputeDurations
        % -----------------------------------------------------------------
        function ComputeDurations( obj )
            % obj.ComputeDurations()
            %
            % Compute durations for each keybinds
            
            kbevents = cell( length(obj.Header) , 2 );
            
            % Take out T_start and T_stop from Data
            
            T_start_idx = strcmp( obj.Data(:,1) , 'StartTime' );
            T_stop_idx = strcmp( obj.Data(:,1) , 'StopTime' );
            
            data = obj.Data( ~( T_start_idx + T_stop_idx ) , : );
            
            % Create list for each KeyBind
            
            [ unique_kb , ~ ,  idx ] = unique_stable(obj.Data(:,1)); % Filter each Kb
            
            % Re-order each input to be coherent with Header order
            input_found = nan(size(unique_kb));
            for c = 1:length(unique_kb)
                
                input_idx  = regexp(obj.Header,unique_kb(c));
                input_idx  = ~cellfun(@isempty,input_idx);
                input_idx  = find(input_idx);
                
                input_found(c) = input_idx;
                
            end
            
            kbevents(:,1) = obj.Header; % Name of KeyBind
            
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
            
            obj.KbEvents = kbevents;
            
        end
        
        % -----------------------------------------------------------------
        %                        GenerateMRITrigger
        % -----------------------------------------------------------------
        function GenerateMRITrigger( obj , tr, volumes )
            % obj.GenerateMRITrigger( TR = positive number , Volumes = positive integer )
            %
            % Generate MRI trigger according to he given number of Volumes
            % and the TR.
            
            % ================ Check input argument =======================
            
            if nargin > 0
                
                % --- tr ----
                if ~( isnumeric(tr) && tr > 0 )
                    error('TR must be positive')
                end
                
                % --- volumes ----
                if ~( isnumeric(volumes) && volumes > 0 && volumes == round(volumes) )
                    error('Volumes must be a positive integer')
                end
                
            else
                
                % narginchk(3,3)
                % narginchk introduced in R2011b
                if nargin ~=3
                    error('%s uses 3 input argument(s)',mfilename)
                end
                
            end
            
            % ======================= Callback ============================
            
            %             MRI_trigger_tag = '5%'; % fORP in USB
            MRI_trigger_tag = obj.Header{1};
            pulse_duration = 0.020; % seconds
            
            % Check if TR is compatible with the pulse duration
            if tr < pulse_duration
                error('pulse_duration is set to %.3f, but TR must be such as TR > pulse_duration',pulse_duration)
            end
            
            % Fill Data whith MRI trigger events
            
            for v = 1 : volumes
                
                obj.AddEvent({ MRI_trigger_tag (v-1)*tr                1 NaN })
                obj.AddEvent({ MRI_trigger_tag (v-1)*tr+pulse_duration 0 NaN })
                
            end
            
        end
        
        % -----------------------------------------------------------------
        %                           BuildGraph
        % -----------------------------------------------------------------
        function BuildGraph( obj )
            % obj.BuildGraph()
            %
            % Build curves for each events, ready to be plotted.
            
            % ================= Build curves for each Kb ==================
            
            for k = 1:size( obj.KbEvents , 1 ) % For each KeyBinds
                
                if ~isempty( obj.KbEvents{k,2} ) % Except for null (usually the last one)
                    
                    data = cell2mat( obj.KbEvents{k,2}(:,1:2) ); % Catch data for this Keybind
                    
                    N  = size( data , 1 ); % Number of data = UP(0) + DOWN(1)
                    
                    % Here we need to build a curve that looks like
                    % recangles
                    for n = N:-1:1
                        
                        % Split data above & under the point
                        dataABOVE = data( 1:n-1 ,: );
                        dataUNDER = data( n:end , : );
                        
                        % Add a point ine curve to build a rectangle
                        switch data(n,2)
                            case 0
                                data  = [ ...
                                    dataABOVE ; ...
                                    dataUNDER(1,1) 1 ;...
                                    dataUNDER ...
                                    ] ;
                            case 1
                                data  = [ ...
                                    dataABOVE ; ...
                                    dataUNDER(1,1) 0 ; ...
                                    dataUNDER ...
                                    ] ;
                                
                            otherwise
                                disp( 'bug' )
                        end
                        
                    end
                    
                    % Now we have a continuous curve that draws rectangles.
                    % The objective now is to 'split' each rectangle, to
                    % have a more convinient display
                    
                    % To find where are two consecutive 0, REGEXP is used
                    data_str  = num2str(num2str(data(:,2)')); % Convert to text
                    data_str  = regexprep(data_str,' ','');   % Delete white spaces
                    idx_data_str = regexp(data_str,'00');     % Find two consecutive zeros
                    
                    % Add NaN between two consecutive zeros
                    for n = length(idx_data_str):-1:1
                        
                        % Split data above & under the point
                        dataABOVE = data( 1:idx_data_str(n) , : );
                        dataUNDER = data( idx_data_str(n)+1:end , : );
                        
                        % Add a point in curve to build a rectangle
                        data  = [ ...
                            dataABOVE ; ...
                            dataUNDER(1,1) NaN ; ...
                            dataUNDER ...
                            ] ;
                        
                    end
                    
                    % Store curves
                    obj.KbEvents{k,3} = data;
                    
                end
                
            end
            
            % Store curves
            obj.GraphData = obj.KbEvents;
            
        end
        
    end % methods
    
    
    methods ( Static )
        
        % -----------------------------------------------------------------
        %                              Start
        % -----------------------------------------------------------------
        function Start
            % obj.Start()
            %
            % Initialise the KeyBind Queue and start collecting the inputs
            
            KbQueueCreate
            KbQueueStart
            
        end
        
        % -----------------------------------------------------------------
        %                              Stop
        % -----------------------------------------------------------------
        function Stop
            % obj.Stop()
            %
            % Stop collecting KeyBinds and Release the device
            
            KbQueueStop
            KbQueueRelease
            
        end
        
    end % methods ( Static )
    
end % class
