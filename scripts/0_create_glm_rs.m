clear matlabbatch;

%% ATTENTION
% this script is for demonstration purposes. 
% it will not run due to the lack of preprocessed images 

%% change this
paths.root =  'C:\Users\David.Willinger\Documents\workshop_brainfood\';
%%

% dont touch
paths.masterfile =   fullfile(paths.root, 'data\subjects.csv'); 
paths.data = fullfile(paths.root, '\dcm\1_lvl\');
paths.scans = 'dummyfolder';

% Define subjects
excludes = {'pmdd-49'};
subjects =           readtable(paths.masterfile); 
subjects = subjects(find(~contains(subjects.id,excludes)),:);

batches = {};

for i=1:1 % height(subjects)    
    
    paths.scans= fullfile(paths.root, 'preprocessing\scans\' );

    %if ~isdir([paths.analysis, '\4_rs\', subjects.id{i}])
    %    mkdir([paths.analysis, '\4_rs\', subjects.id{i}]);
    %end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%% SPECIFY 1ST LEVEL %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    clear matlabbatch;
    %matlabbatch{1}.spm.stats.fmri_spec.dir = [path, analysisPath, timePoint, task, subject{i}];
    matlabbatch{1}.spm.stats.fmri_spec.dir = [paths.data, subjects.id{i}];
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';

    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 2.3;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 33;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = median(flip([1:1:33]));
    % ['O:\studies\pmdd\mri\preprocessing\', timePoint, task, subject{i},'\']
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = cellstr(spm_select('ExtFPList', [paths.scans, subjects.id{i},'\'], '^s6w.*.nii$' ,Inf));
    
    % create GLM for Resting state as in https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=spm;15143960.1802
    N  = 200; % number of scans
    TR = 2.3; % TR in {s}
    h  = [0.0078 0.1]; % {Hz}
    n  = fix(2*(N*TR)*h + 1);
    X  = spm_dctmtx(N);
    X  = X(:,n(1):n(2));
    save(fullfile([paths.data, subjects.id{i}],'DCT.txt'),'X','-ascii');
    
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress = struct('name', {}, 'val', {});
    
    realignment_params = ls ( [paths.scans subjects.id{i} '\rad*.txt']);
    file_bad_scans = ls ([paths.scans subjects.id{i} '\bad_scans*.txt']); 
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = { [ paths.data, subjects.id{i},'\', 'DCT.txt']
                                                             [ paths.scans, subjects.id{i} '\', realignment_params] 
                                                             [ paths.scans, subjects.id{i}, '\', file_bad_scans]   };
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128;
   
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.1;
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'none';


    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ONSETS / PARAMETER VALUES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         
        
    %select a directory where the SPM.mat file containing the specified
    %design matrix will be written
    matlabbatch{1}.spm.stats.fmri_spec.dir = cellstr([paths.data, subjects.id{i}]);
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%% ESTIMATE %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%
    
    %select SPM.mat file that contains the design specification

    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%% CONTRASTS %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %select SPM.mat file for contrasts
    matlabbatch{3}.spm.stats.con.spmmat = {[paths.data, subjects.id{i},'\SPM.mat']};
    %matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    
    %define contrasts
    idx_con = 1;
    matlabbatch{3}.spm.stats.con.consess{idx_con}.fcon.name = 'Effects of interest';
    matlabbatch{3}.spm.stats.con.consess{idx_con}.fcon.weights = eye(size(X,2));
    matlabbatch{3}.spm.stats.con.consess{idx_con}.fcon.sessrep = 'none';
    idx_con = idx_con + 1;
    
    matlabbatch{3}.spm.stats.con.delete = 1;
   
    batches{i} = matlabbatch; 
end

%% uncomment this, to estimate the GLMs for each subject (not recommended)
return

% parpool(4);

% parfor j = 1:length(batches)
%     %run the batch
%   spm_jobman('run', batches{j}); 
% end  

