% (C) Copyright 2019 bidspm developers

%%% Script for preprocessing pipeline with bidspm()
%%% Due to SliceTiming errors in DCM files slice timing is skipped
%%% to run, needs bidspm() installed and path added and saved. 

clear;
clc;

%% Paths after moving to external hard drive! 

%% initialize bidspm() for this matlab session
%bidspm in code/lib/bidspm
addpath(fullfile(pwd, '..', '..','lib', 'bidspm'));

bidspm();

%% set up BIDS folders and paths
this_dir = fileparts(mfilename('fullpath'));
root_dir = fullfile(this_dir, '..', '..', '..');

bids_dir = fullfile(root_dir,'inputs','raw');
output_dir = fullfile(root_dir, 'outputs','derivatives');

%% define subjects and tasks to preprocess
subject_label = 'pilot01'; 

%task_label = 'deafCATvisual'; %visual task only 
task_label = 'deafCATaudio'; %visual task only 

%% does preproc without Slice Timing Correction

    bidspm(bids_dir, output_dir, 'subject', ...
        'participant_label', {subject_label}, ...
        'action', 'preprocess', ...
        'task', task_label, ...
        'verbosity', 1, ...
        'ignore', {'slicetiming'}, ... 
        'space', {'individual', 'IXI549Space'}, ...
        'fwhm', 6);