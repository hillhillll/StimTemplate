classdef EventRecorder < handle
    
    %EVENTRECORDER Class to record any stimulation events
    
    %% Properties
    
    properties
        
        Data           = cell(0)                 % cell( NumberOfEvents , Columns )
        Header         = {''}                    % str : Description of each columns
        Columns        = 0                       % double(positive integer)
        Description    = mfilename( 'fullpath' ) % str : Fullpath of the file
        TimeStamp      = datestr( now )          % str : Time stamp for the creation of object
        NumberOfEvents = 0                       % double(positive integer)
        EventCount     = 0                       % double(positive integer)
        GraphData      = cell(0)                 % cell( 'ev1' curve1 ; 'ev2' curve2 ; ... )
        BlockData      = cell(0)                 % cell( ? , Columns )
        BlockGraphData = cell(0)                 % cell( ? , Columns )
        
    end % properties
    
    %% Methods
    
    methods
        
        % -----------------------------------------------------------------
        %                           Constructor
        % -----------------------------------------------------------------
        function obj = EventRecorder( header , numberofevents )
            % obj = EventRecorder( Header = cell( 1 , Columns ) , NumberOfEvents = double(positive integer) )
            
            % Usually, first column is the event name, and second column is
            % it's onset.
            
            % ================ Check input argument =======================
            
            % Arguments ?
            if nargin > 0
                
                % --- header ----
                if isvector( header ) && ...
                        iscell( header ) && ...
                        ~isempty( header ) % Check input argument
                    if all( cellfun( @isstr , header ) )
                        obj.Header =  header ;
                    else
                        error( 'Header should be a line cell of strings' )
                    end
                else
                    error( 'Header should be a line cell of strings' )
                end
                
                % --- numberofevents ---
                if isnumeric( numberofevents ) && ...
                        numberofevents == round( numberofevents ) && ...
                        numberofevents > 0 % Check input argument
                    obj.NumberOfEvents = numberofevents;
                else
                    error( 'NumberOfEvents must be a positive integer' )
                end
                
                % ================== Callback =============================
                
                obj.Columns = length( header );
                obj.Data    = cell( numberofevents , obj.Columns );
                
            else
                % Create empty StimEvents
            end
            
        end
        
        
        %         % -----------------------------------------------------------------
        %         %                             saveobj
        %         % -----------------------------------------------------------------
        %         function s = saveobj(obj)
        %
        %             s = struct; % Create a sctructure
        %             props = properties(obj);
        %             for p = 1:numel(props)
        %                 s.(props{p})=obj.(props{p}); % Fill the structer with the object properties
        %             end
        %
        %         end
        
    end % methods
    
    %     methods ( Static )
    %
    %         % -----------------------------------------------------------------
    %         %                             loadobj
    %         % -----------------------------------------------------------------
    %         function obj = loadobj(s)
    %
    %             if isstruct(s) % if the object was saved as a structure
    %
    %                 % Fetch class name
    %                 [~, classsName, ~] = fileparts(s.Description);
    %
    %                 newObj = feval(str2func(classsName)); % Create an empty instance
    %                 props = properties(newObj);
    %                 for p = 1:numel(props)
    %                     try
    %                         newObj.(props{p})=s.(props{p}); % Fill the instance
    %                     catch err
    %                         warning(err.message)
    %                     end
    %                 end
    %                 obj = newObj; % Assign the pointer
    %
    %             else % if the object was saved as an object
    %
    %                 obj = s;
    %
    %             end
    %
    %         end
    %
    %     end % methods ( Static )
    
end % class
