%% stitch_probs
prob_thresh = 0.5;
plot_mean = 1;
chunk_dur = 10*60;
nchunks = 72;
sz_chunk = 37;
npoints = 9585;

%% Paths
spike_prob_path = '../../spike_probs/';
eeg_data_path = '../../eeg_data/';

%% Load the meta file
%meta = load(sprintf('%ssz_%d/meta.mat',eeg_data_path,which_sz));
%meta = meta.meta;

%% Path to the spike probs
curr_prob_path = [spike_prob_path,sprintf('sz_%d',which_sz),'/'];


%% Initialize stuff
probs = nan(npoints*nchunks,1);
times = linspace(0,nchunks*chunk_dur,npoints*nchunks);
transitions = nan(npoints*nchunks,1);
mean_probs = nan(npoints*nchunks,1);

% Loop over the probs
for i = 1:nchunks

    curr_transitions = zeros(npoints,1);
    if i == sz_chunk-1
        curr_transitions(end) = 2;
    else
        curr_transitions(end) = 1;
    end
    transitions((i-1)*npoints+1:i*npoints,1) = curr_transitions;

    if ~exist([curr_prob_path,sprintf('chunk_%d_sn2r11.csv',i)],"file")
        fprintf('\ncan''t find chunk %d\n',i);
        continue;
    end

    % Load the prob
    T = readtable([curr_prob_path,sprintf('chunk_%d_sn2r11.csv',i)]);

    % convert to array
    a = table2array(T);
    probs((i-1)*npoints+1:i*npoints,1) = a;
    mean_probs((i-1)*npoints+1:i*npoints,1) = sum(a>prob_thresh);


end
times = times/3600;


%% plot it
figure
set(gcf,'Position',[1 1 1400 1000])
if plot_mean
    plot(times,mean_probs,'LineWidth',2);
else
    plot(times,probs);
end
hold on
for i = 1:length(transitions)
    if transitions(i) == 1
        plot([times(i) times(i)],ylim,'k--');
    end
    if transitions(i) == 2
        plot([times(i) times(i)],ylim,'r--','LineWidth',2);
    end

end

fprintf('\nplotting sz %d\n',which_sz);