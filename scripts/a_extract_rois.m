% Define subjects
clear matlabbatch;

%% change this
paths.root =  'C:\Users\David.Willinger\Documents\workshop_brainfood\';
%%

% dont touch
paths.masterfile =   fullfile(paths.root, 'data\subjects.csv'); 
paths.data = fullfile(paths.root, '\dcm\1_lvl\');

% Define subjects
excludes = {'pmdd-49'};
subjects =           readtable(paths.masterfile); 
subjects = subjects(find(~contains(subjects.id,excludes)),:);



rois_coord = {
[-19 -2 -21] 
[19 -2 -21]
[0 -52 7]
[-1 54 27]
[0 21 36]
};

rois_names = {
    'l_amy',...
    'r_amy',...
    'precuneus',...
    'medial_pfc',...
    'acc'
};

rois_mask = {
    '','','','',''
};


% generate rois
batches = {};
for s = 1:height(subjects)
    for r = 1:length(rois_names)
        clear matlabbatch
        matlabbatch{1}.spm.util.voi.spmmat = {fullfile(paths.data,subjects.id{s},'SPM.mat')};
        matlabbatch{1}.spm.util.voi.adjust = 1;
        matlabbatch{1}.spm.util.voi.session = 1;

        voi_name = [rois_names{r} '_' num2str(rois_coord{r}(1)) '_' num2str(rois_coord{r}(2)) '_' num2str(rois_coord{r}(3)) ];

        matlabbatch{1}.spm.util.voi.name = voi_name;
        matlabbatch{1}.spm.util.voi.roi{1}.spm.spmmat = {fullfile(paths.data,subjects.id{s},'SPM.mat')};
        matlabbatch{1}.spm.util.voi.roi{1}.spm.contrast = 1;
        matlabbatch{1}.spm.util.voi.roi{1}.spm.conjunction = 1;
        matlabbatch{1}.spm.util.voi.roi{1}.spm.threshdesc = 'none';
        matlabbatch{1}.spm.util.voi.roi{1}.spm.thresh = 0.05;
        matlabbatch{1}.spm.util.voi.roi{1}.spm.extent = 0;
        matlabbatch{1}.spm.util.voi.roi{1}.spm.mask = struct('contrast', {}, 'thresh', {}, 'mtype', {});
        
        if (strcmp(rois_mask{r},''))
                % search sphere, radius = 6mm
                matlabbatch{1}.spm.util.voi.roi{2}.sphere.centre = rois_coord{r};
                matlabbatch{1}.spm.util.voi.roi{2}.sphere.radius = 8;
                matlabbatch{1}.spm.util.voi.roi{2}.sphere.move.fixed = 1;
                matlabbatch{1}.spm.util.voi.roi{3}.sphere.centre = [0 0 0];
                matlabbatch{1}.spm.util.voi.roi{3}.sphere.radius = 8;
                matlabbatch{1}.spm.util.voi.roi{3}.sphere.move.local.spm = 1;
                matlabbatch{1}.spm.util.voi.roi{3}.sphere.move.local.mask = 'i2';
                matlabbatch{1}.spm.util.voi.expression = 'i1&i3';
            else
                % search in anatomical mask
                matlabbatch{1}.spm.util.voi.roi{2}.sphere.centre = rois_coord{r};
                matlabbatch{1}.spm.util.voi.roi{2}.sphere.radius = 12;
                matlabbatch{1}.spm.util.voi.roi{2}.sphere.move.fixed = 1;
                matlabbatch{1}.spm.util.voi.roi{3}.mask.image = cellstr(rois_mask{r});
                matlabbatch{1}.spm.util.voi.roi{3}.mask.threshold = 0;
                matlabbatch{1}.spm.util.voi.roi{4}.sphere.centre = [0 0 0];
                matlabbatch{1}.spm.util.voi.roi{4}.sphere.radius = 6;
                matlabbatch{1}.spm.util.voi.roi{4}.sphere.move.local.spm = 1;
                matlabbatch{1}.spm.util.voi.roi{4}.sphere.move.local.mask = 'i2&i3';
                matlabbatch{1}.spm.util.voi.expression = 'i1&i4';
        end

        
        
        batches{s*length(rois_coord)+r-length(rois_coord)} = matlabbatch;
        %batches{s*length(1)+r-length(1)} = matlabbatch;
    end     
end
return
% return
% spm_jobman('interactive',batches{i});
  if isempty(gcp('nocreate'))
      parpool(8);
  end
%  
  parfor i = 1:length(batches)
      spm_jobman('run',batches{i});
  end    
