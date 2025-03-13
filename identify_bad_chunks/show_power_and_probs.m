%% show probs and power

%% stitch_probs
prob_thresh = 0.5;
plot_mean = 1;
chunk_dur = 10*60;
nchunks = 72;
sz_chunk = 37;
npoints = 9585;
nsegs_per_chunk = 10;
secs_per_seg = 60;


%% Paths
spike_prob_path = '../../spike_probs/';
spectral_path = '../../spectral_data/';

%% Sub-paths
curr_prob_path = [spike_prob_path,sprintf('sz_%d',which_sz),'/'];
curr_spectral_path = [spectral_path,sprintf('sz_%d',which_sz),'/'];

%% Initialize stuff
times = linspace(0,nchunks*chunk_dur,nchunks*nsegs_per_chunk);
transitions = nan(nchunks*nsegs_per_chunk,1);
mean_probs = nan(nchunks*nsegs_per_chunk,1);
all_bp1 = nan(nchunks*nsegs_per_chunk,1);
all_bp2 = nan(nchunks*nsegs_per_chunk,1);
file_times = nan(nchunks,1);


% Prep transitions
count = 0;
for i = 1:nchunks

    for j = 1:nsegs_per_chunk
        if i == sz_chunk-1 && j == nsegs_per_chunk
            curr_transitions = 3;
        elseif j == nsegs_per_chunk
            curr_transitions = 2;
        else
            curr_transitions = 1;
        end
        count = count + 1;
        transitions(count) = curr_transitions;

    end

end

% Loop over the probs
for i = 1:nchunks

    

    if ~exist([curr_prob_path,sprintf('chunk_%d_sn2r11.csv',i)],"file")
        continue;
    end

    % Load the prob
    T = readtable([curr_prob_path,sprintf('chunk_%d_sn2r11.csv',i)]);

    % convert to array
    a = table2array(T);

    % get times
    a_times = linspace(0,chunk_dur,length(a));
    %mean_probs(i,1) = sum(a>prob_thresh);


    % load the BP
    if ~exist([curr_spectral_path,sprintf('chunk_%d.mat',i)],"file")
        continue
    end
    load([curr_spectral_path,sprintf('chunk_%d.mat',i)]);

    bp_of_interest1 = bp.sixtyHz;
    mean_bp1 = mean(bp_of_interest1(:,~strcmp(bipolar_labels,'-') & ...
        ~contains(bipolar_labels,'EKG')),2);

    bp_of_interest2 = bp.gamma;
    mean_bp2 = mean(bp_of_interest2(:,~strcmp(bipolar_labels,'-') & ...
        ~contains(bipolar_labels,'EKG')),2);

    % Now bin it
    for j = 1:nsegs_per_chunk
        all_bp1((i-1)*nsegs_per_chunk + j) = mean_bp1(j);
        all_bp2((i-1)*nsegs_per_chunk + j) = mean_bp2(j);

        prob_times = a_times > (j-1)*secs_per_seg & a_times < j*secs_per_seg;
        mean_probs((i-1)*nsegs_per_chunk + j) = sum(a(prob_times) > prob_thresh);
    
    end

    file_times(i) = curr_times(1);

end
%times = times/3600;


figure
set(gcf,'Position',[1 1 1400 1000])
tiledlayout(3,1,'TileSpacing','tight')
nexttile
plot(mean_probs,'LineWidth',2);
ylabel('Probs')
hold on
%
for i = 1:length(transitions)
    if transitions(i) == 2
        plot([i i],ylim,'k--');
    end
    if transitions(i) == 3
        plot([i i],ylim,'r--','LineWidth',2);
    end

end
xlim([0 length(mean_probs)])
%


nexttile
plot(all_bp1,'LineWidth',2);
ylabel('Power 60 Hz')
%
hold on
for i = 1:length(transitions)
    if transitions(i) == 2
        plot([i i],ylim,'k--');
    end
    if transitions(i) == 3
        plot([i i],ylim,'r--','LineWidth',2);
    end

end
xlim([0 length(transitions)])


nexttile
plot(all_bp2,'LineWidth',2);
ylabel('Power gamma')
%
hold on
for i = 1:length(transitions)
    if transitions(i) == 2
        plot([i i],ylim,'k--');
    end
    if transitions(i) == 3
        plot([i i],ylim,'r--','LineWidth',2);
    end

end
xlim([0 length(transitions)])
%}
%{
nexttile
plot(1:72,file_times)
hold on
for i = 1:72
    plot([i i],ylim,'--k')
end
xlim([0 72])
fprintf('\nplotting sz %d\n',which_sz);

%}