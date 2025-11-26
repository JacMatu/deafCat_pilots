% cosmo MVPA

function cosmomvpa_RSA_DeafCat(opt,sub_input)

% be very verbose please
cosmo_warning('off')

opt.subjects = sub_input;

%% Loop through subjects

for iSub = 1:numel(opt.subjects)
    
    opt.cosmomvpa.pathData = fullfile(opt.dir.stats, ...
        ['sub-' opt.subjects{iSub}], ...
        opt.dir.statsTask);
    
    
    %Grab the ROIs based on opt.cosmomvpa.ROIlabel!
    BIDS = bids.layout(opt.dir.rois, ...
        'use_schema', false);
    
    % querry ROIs based on atlas or spheres
    if strcmp(opt.cosmomvpa.ROInature, 'atlas')
        opt.query = [];
        opt.query.sub = opt.subjects{iSub};
        opt.query.modality = 'roi';
        opt.query.suffix = 'mask';
        opt.query.atlas = opt.cosmomvpa.ROIlabel;
        opt.query.space = 'MNI';
        opt.query.desc = ''; %take only ROIs without desc-groupmasked!
    elseif strcmp(opt.cosmomvpa.ROInature, 'sphere')
        opt.query = [];
        opt.query.sub = opt.subjects{iSub};
        opt.query.modality = 'roi';
        opt.query.suffix = 'mask';
        opt.query.radius = [num2str(opt.cosmomvpa.roiDimension),'mm'];
        opt.query.label = opt.cosmomvpa.ROIlabel;
        opt.query.space = opt.cosmomvpa.space;
    end
    opt.cosmomvpa.roiFileNames = bids.query(BIDS, 'data', ...
        opt.query);
    
    
    % get FFX path
    subID = opt.subjects{iSub};
    
    % this can be coded better (eg it is good to have the exact nb of runs for each subject even
    % though it is the same nb repeated)
    nbRun = opt.cosmomvpa.nbRun(1);
    
    pathData = opt.cosmomvpa.pathData;
    
    fprintf(['\n For subj: ' subID '\n\n']);
    
    % loop through ffxResults (beta and tmaps)
    
    
    for iFfxResult = 1:length(opt.cosmomvpa.ffxResults)
        
        fprintf(['\n For ffx result: ' opt.cosmomvpa.ffxResults{iFfxResult} '\n\n']);
        
        % set the 4D result image
        resultsImage = fullfile(pathData, ['sub-' opt.subjects{iSub} ...
            '_task-' opt.taskName ...
            '_space-' opt.cosmomvpa.space ...
            '_desc-4D_' opt.cosmomvpa.ffxResults{iFfxResult} ...
            '.nii']);
        
        % loop through ROI dimension and area
        
        
        
        
        roiFileNames = opt.cosmomvpa.roiFileNames;
        
        for i = 1:length(roiFileNames)
            
            roiMasks{i} = roiFileNames{i};
            
        end
        
        %% ROI MVPA analyses
        
        for iMask = 1:length(roiMasks)
            
            
            % define brain mask
            mask = roiMasks{iMask};
            
            roiName = roiMasks{iMask};
            
            [~, roiName, ~] = fileparts(roiName);
            
            bidspart = split(roiName, "_");
            
            % atlas and spheres have LABEL in different part of name
            if strcmp(opt.cosmomvpa.ROInature, 'atlas')
                label = split(bidspart(5), '-');
            else
                label = split(bidspart(3), '-');
            end
            
            roiName = label{2};
            
            fprintf(['\nMask: ' roiName '\n\n']);
            
            labels = opt.cosmomvpa.labels;
            
            % loop through modalities
            %for iModality = 1:numel(opt.cosmomvpa.modalities)
            
            fprintf([' Modality: ' opt.cosmomvpa.modality '\n\n']);
            
            % define the data structure
            ds = cosmo_fmri_dataset(resultsImage, 'mask', mask);
            
            % getting rid off zeros
            zero_msk = all(ds.samples == 0, 1);
            
            ds = cosmo_slice(ds, ~zero_msk, 2);
            
            % set chunks, targets and labels
            
            stim = [1:24];
            
            ds = setTargetsChunksLabels(opt, ds, stim, labels, nbRun);
            
            % remove constant features
            ds = cosmo_remove_useless_data(ds);
            
            % ------------------------------------------
            % Average trials per condition (REQUIRED for RSA)
            % ------------------------------------------
            ds = cosmo_fx(ds, @(x) mean(x,1), 'targets');
            % Now ds.sa.targets contains exactly 1 sample per condition.
            
            % Save condition labels BEFORE RSA
            cond_labels = ds.sa.targets;
            
            % ------------------------------------------
            % RSA dissimilarity computation
            % ------------------------------------------
            measure = @cosmo_dissimilarity_matrix_measure;
            args = struct();
            
            rsa_ds = measure(ds, args);    % vector DSM
            
            dsm_vec = rsa_ds.samples;      % DSM vector
            
            %conditions = rsa_ds.sa.targets; % condition labels
            
            %save the things
            DSMSaveName = fullfile(opt.cosmomvpa.pathOutput, ...
                ['sub-', opt.subjects{iSub}, ...
                '_task-', opt.taskName, ...
                '_label-', roiName, ...
                '_desc-smth', num2str(opt.cosmomvpa.funcFWHM), ...
                '_RSA_DSM.mat']);
            
            save(DSMSaveName, 'dsm_vec', 'cond_labels');
            
            
            
        end
    end
end
end





function ds = setTargetsChunksLabels(opt, ds, stim, labels, nbRun)

% set chunks (runs by trial_type), target (stimulation type - modality),
% names (stimulation type name)
trialsPerRun = length(stim) * opt.cosmomvpa.nbTrialRepetition;

chunks = repmat((1:nbRun)', 1, opt.cosmomvpa.nbTrialRepetition)';
chunks = chunks(:);
chunks = repmat(chunks, trialsPerRun, 1);

targets = repmat(stim', 1, nbRun)';
targets = targets(:);

labels = repmat(labels', 1, nbRun)';
labels = labels(:);

ds.sa.targets = targets;
ds.sa.chunks = chunks;
ds.sa.labels = labels;

end
