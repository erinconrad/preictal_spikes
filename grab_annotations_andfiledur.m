function T = grab_annotations_andfiledur(ieeg_name,ieeg_path,pwfile,login_name)


%% Add paths
addpath(genpath(ieeg_path));

% Initialize session
attempt = 1;
while 1
    try
        session = IEEGSession(ieeg_name,login_name,pwfile);
        break
    catch ME
        if contains(ME.message,'503') || contains(ME.message,'504') || ...
                contains(ME.message,'502') || contains(ME.message,'500')
            attempt = attempt + 1;
            fprintf('Failed to retrieve ieeg.org data, trying again (attempt %d)\n',attempt); 
        else
            ME
            fprintf('\nNon-server error\n');
            T = [];
            return
            
        end
    end
    if attempt == 20
        error('Too many server errors');
    end
end

% get duration (convert to seconds)
duration = session.data.rawChannels(1).get_tsdetails.getDuration/1e6;

n_layers = length(session.data.annLayer);

annotation_times = [];
annotations = {};

clear ann
for ai = 1:n_layers
    
    count = 0;
    
    while 1 % while loop because ieeg only lets you pull 250 at once
        
        % ask it to pull next (up to 250) events after count
        if count == 0
            a=session.data.annLayer(ai).getEvents(count);
        else
            try
                a=session.data.annLayer(ai).getNextEvents(a(n_ann));
            catch % this happened once, very bizzare, can't figure out error, possibly because exactly 250 annotations?
                a = [];
            end
        end
        if isempty(a), break; end
        n_ann = length(a);
        for k = 1:n_ann
            annotation_times = [annotation_times; a(k).start/(1e6)];
            type = a(k).type;
            description = a(k).description;
            combined = sprintf('type: %s; description: %s',type,description);
            annotations = [annotations;combined];
            assert(length(a(k).start)==1)
        end
        
        count = count + n_ann;
    end
    
    
end

assert(length(annotations) == length(annotation_times))
duration = repmat(duration,length(annotation_times),1);

T = table(annotation_times,annotations,duration,...
    'VariableNames',{'annotation_times','annotations','file_duration'});

%% Delete session
session.delete;


end