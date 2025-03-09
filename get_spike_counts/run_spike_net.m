%% Goal
%{
Here I will loop over a bunch of directories representing different
seizures, each directory containing mat files corresponding to 10 minute
chunks of eeg data surrounding the seizure. For each directory, I will run
spike net, thus outputting spike probabilities in a separate directory

%}

if ~exist("start_sz","var")
    error('list start sz');
end

if ~exist("end_sz","var")
    error('please specify end_sz');
end

%% Paths
spikenet2_env = '/mnt/sauce/littlab/users/erinconr/conda_env/spikenet2';
spikenet2_script_path = '/mnt/sauce/littlab/users/erinconr/utilities/SN2R11_demo_20240715/';
eeg_dir = '/mnt/sauce/littlab/users/erinconr/projects/preictal_spikes/eeg_data/';
spike_prob_dir = '/mnt/sauce/littlab/users/erinconr/projects/preictal_spikes/spike_probs/';
spike_net_script = 'run_sn2r11.py';

%% CD to spike net directory
cd(spikenet2_script_path)

% Loop over eeg subdirs
listing = dir(eeg_dir);
for i = 1:length(listing)

    % Skip if not an expected name
    if ~contains(listing(i).name,'sz') || strcmp(listing(i).name(1),'.')
        continue;
    end

    numStr = regexp(listing(i).name,'\d+','match');
    if str2num(numStr{1})<start_sz, continue; end
    if str2num(numStr{1})>end_sz, continue; end

    % get the full path
    curr_eeg_path = [listing(i).folder,'/',listing(i).name,'/'];

    % Look for and delete files within the eeg path that start with '._'. These will
    % screw up spike net
    sublisting = dir(curr_eeg_path);
    for j = 1:length(sublisting)
        if startsWith(sublisting(j).name,'.') && contains(sublisting(j).name,'mat')
            delete([curr_eeg_path,sublisting(j).name]);
        end
    
    end



    % Make output path
    curr_prob_path = [spike_prob_dir,listing(i).name,'/'];
    mkdir(curr_prob_path);

    fprintf('\nRunning spike net for %s\n',listing(i).name);

    %% Run spike net
    system(sprintf('conda run -p %s python %s %s %s',...
        spikenet2_env,spike_net_script,curr_eeg_path,curr_prob_path));

    

end

