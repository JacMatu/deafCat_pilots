% Adjustting Marco's script to my data

clear;
clc;

this_dir = '/Volumes/Slim_Reaper/Projects/deafCatNencki/deafCat_pilots/code/src/cosmo-mvpa-RSA';

addpath(fullfile(this_dir, '..', '..', 'lib', 'bidspm'));

bidspm();

opt.dir.root = fullfile(this_dir, '..', '..', '..');
opt.dir.derivatives = fullfile(opt.dir.root, 'outputs', 'derivatives');
opt.dir.stats = fullfile(opt.dir.root, 'outputs', 'derivatives', 'bidspm-stats');
opt.dir.rois = fullfile(opt.dir.root, 'outputs', 'derivatives', 'bidspm-roi'); %remember to create this folder with ROIs inside
opt.dir.mvpa = fullfile(opt.dir.derivatives, 'cosmo-mvpa-RSA');

if ~exist(opt.dir.mvpa, 'dir')
    mkdir(opt.dir.mvpa)
end




%% MVPA settings

opt.cosmomvpa.funcFWHM = 2; %changed from 0
opt.cosmomvpa.space = 'IXI549Space'; %preproc/normalisation space
opt.cosmomvpa.ROInature = 'atlas'; %'atlas' or 'sphere'
%opt.cosmomvpa.ROIlabel = 'cVWFA'; %changed from 'MT' other labels to test: aVWFA, cVWFA, pVWFA, perVWFA
%opt.cosmomvpa.ROIlabel = 'LexPerVWFA';
%opt.cosmomvpa.ROIlabel = 'visfatlas';
%opt.cosmomvpa.ROIlabel = 'hcpex';
opt.cosmomvpa.ROIlabel = 'JuBrain';

opt.cosmomvpa.normalization = 'zscore';

opt.cosmomvpa.measure = @cosmo_target_dsm_corr_measure;

%Target DSMs: categorical models / low-level models...

% design info
opt.cosmomvpa.nbTrialRepetition = 1; % ??? 

opt.cosmomvpa.nbRun = 4; 

% decoding info (modalities, conditions to decode, labels)
modality = 'visual'; % 'audio' or 'visual'
opt.cosmomvpa.modality = 'visual'; %'audio' 

% define conditions to test based on labels
opt.cosmomvpa.labels = { 'ANIMAL_BIRD_1', 'ANIMAL_BIRD_2', 'ANIMAL_BIRD_3',...
    'ANIMAL_OTHER_4','ANIMAL_OTHER_5','ANIMAL_OTHER_6', ...
    'BIG_ENV_1', 'BIG_ENV_2', 'BIG_ENV_3',...
    'BIG_MEC_4','BIG_MEC_5','BIG_MEC_6', ...
     'HUMAN_NONVOC_1', 'HUMAN_NONVOC_2', 'HUMAN_NONVOC_3',...
     'HUMAN_VOC_4', 'HUMAN_VOC_5',  'HUMAN_VOC_6', ...
     'MANIP_ACTWITH_1','MANIP_ACTWITH_2','MANIP_ACTWITH_3',...
     'MANIP_GRASPON_4','MANIP_GRASPON_5','MANIP_GRASPON_6'};

%% Setup output dirs for MVPA

opt.taskName = ['deafCAT', modality];
opt.dir.statsTask = ['task-',opt.taskName,'_space-IXI549Space_FWHM-2_node-MVPA24betas'];

opt.cosmomvpa.pathOutput = fullfile(opt.dir.derivatives, 'cosmo-mvpa-rsa', opt.dir.statsTask,opt.cosmomvpa.ROIlabel);

if ~exist(opt.cosmomvpa.pathOutput, 'dir')
    mkdir(opt.cosmomvpa.pathOutput)
end


%% Pick your subjects

%List the sub numbers
 opt.subjects={'pilot02'}; %,'pilot02'

%% RUN mvpa analyses - this computes brain DSMs that you can load later 

opt.cosmomvpa.ffxResults = {'beta'};

cosmomvpa_RSA_DeafCat(opt, opt.subjects);


%% Load DSMs: categorical and hmax C1 (stimuli order = alphabetical
% DSMs are turned into vectors with off-diagonal values with 'squareform'
% function. Size = 1 x 276 (24 stimuli) 

load(fullfile(this_dir, 'DSMs', 'deafCAT_RSA_categorical_dsm_4cat_vector.mat'));
load(fullfile(this_dir, 'DSMs', 'deafCAT_RSA_categorical_dsm_8cat_vector.mat'));
load(fullfile(this_dir, 'DSMs', 'deafCAT_RSA_hmax_C1_dsm_vector.mat'));




%% Test: load DSMs from brain

%FG
load('/Volumes/Slim_Reaper/Projects/deafCatNencki/deafCat_pilots/outputs/derivatives/cosmo-mvpa-RSA/task-deafCATvisual_space-IXI549Space_FWHM-2_node-MVPA24betas/JuBrain/sub-pilot02_task-deafCATvisual_label-FG_desc-smth2_RSA_DSM.mat');

rho_FG_cat4 = corr(cat4_24vec(:), dsm_vec_FG(:), 'type', 'Spearman');
rho_FG_hmax = corr(dsm_24_orig(:), dsm_vec_FG(:), 'type', 'Spearman');

%V1
load('/Volumes/Slim_Reaper/Projects/deafCatNencki/deafCat_pilots/outputs/derivatives/cosmo-mvpa-RSA/task-deafCATvisual_space-IXI549Space_FWHM-2_node-MVPA24betas/JuBrain/sub-pilot02_task-deafCATvisual_label-V1_desc-smth2_RSA_DSM.mat');

rho_V1_cat4 = corr(cat4_24vec(:), dsm_vec_V1(:), 'type', 'Spearman');
rho_V1_hmax = corr(dsm_24_orig(:), dsm_vec_V1(:), 'type', 'Spearman');


%% Test: plot the correlations
% Organize correlations into a matrix:
% rows = ROIs, columns = models
corr_matrix = [
    rho_FG_cat4   rho_FG_hmax;   % FG
    rho_V1_cat4   rho_V1_hmax    % V1
];

roi_labels = {'FG', 'V1'};
model_labels = {'Cat4 Model', 'HMAX Model'};

figure;
bar(corr_matrix);

set(gca, 'XTickLabel', roi_labels, 'FontSize', 12);
xlabel('ROI', 'FontSize', 14);
ylabel('Spearman R', 'FontSize', 14);
legend(model_labels, 'Location', 'NorthWest');
title('RSA correlations per ROI', 'FontSize', 16);

ylim([-1 1]); % optional, typical range for RSA correlations
grid on;

%% Plot brain DSMs
% Store DSM vectors and ROI labels in arrays
dsm_vecs = {dsm_vec_FG, dsm_vec_V1};
roi_labels = {'FG', 'V1'};

num_conditions = 24;  % change if needed

for iROI = 1:length(dsm_vecs)
    
    % Convert vector to square DSM
    dsm_mat = squareform(dsm_vecs{iROI});
    
    % Plot
    figure;
    imagesc(dsm_mat);
    axis square;
    colormap('parula');
    colorbar;
    set(gca, 'XTick', 1:num_conditions, 'YTick', 1:num_conditions);
    xlabel('Condition');
    ylabel('Condition');
    title(sprintf('Brain DSM (%s ROI)', roi_labels{iROI}), 'FontSize', 14);
    
end



