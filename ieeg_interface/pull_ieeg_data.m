function [data,fs,chLabels] = pull_ieeg_data(ieeg_name,pwfile,login_name,times)


% Initialize session
attempt = 1;
while 1
    try
        session = IEEGSession(ieeg_name,login_name,pwfile);
        chLabels = session.data.channelLabels(:,1);
        nchs = size(chLabels,1);

        fs = session.data.sampleRate;
        % Convert times to indices
        run_idx = round(times(1)*fs):round(times(2)*fs);

        if ~isempty(run_idx)
            % Break the number of channels in half to avoid wacky server errors
            values1 = session.data.getvalues(run_idx,1:floor(nchs/4));
            values2 = session.data.getvalues(run_idx,floor(nchs/4)+1:floor(2*nchs/4));
            values3 = session.data.getvalues(run_idx,floor(2*nchs/4)+1:floor(3*nchs/4)); 
            values4 = session.data.getvalues(run_idx,floor(3*nchs/4)+1:nchs); 

            data = [values1,values2,values3,values4];
        else
            data = [];
        end
        
        break
    catch ME
        if contains(ME.message,'503') || contains(ME.message,'504') || ...
                contains(ME.message,'502') || contains(ME.message,'500')
            attempt = attempt + 1;
            fprintf('Failed to retrieve ieeg.org data, trying again (attempt %d)\n',attempt); 
        else
            ME
            fprintf('\nNon-server error\n');
            data = []; fs = []; chLabels = [];
            return
            
        end
    end
    if attempt == 20
        error('Too many server errors');
    end
end




%% Delete session
session.delete;


end