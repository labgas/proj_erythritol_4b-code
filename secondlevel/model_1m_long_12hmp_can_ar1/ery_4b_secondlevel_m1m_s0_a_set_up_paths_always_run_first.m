%% ery_4b_secondlevel_m1m_s0_a_set_up_paths_always_run_first.m
%
% 
% USAGE
% 
% Always run this first before you run other CANlab_help_examples second level batch scripts.
%
%
% CANLAB NOTES
%
% - standard folders and variable names are created by these scripts
%
% - in "prep_" scripts: 
%   image names, conditions, contrasts, colors, global gray/white/CSF
%   values are saved automatically in a DAT structure
% 
% - extracted fmri_data objects are saved in DATA_OBJ variables
% - contrasts are estimated and saved in DATA_OBJ_CON variables
%
% - files with these variables are saved and loaded automatically when you
%   run the scripts
%   meta-data saved in image_names_and_setup.mat
%   image data saved in data_objects.mat
%
% - you only need to run the prep_ scripts once.  After that, use 
%   b_reload_saved_matfiles.m to re-load saved files
% 
% - when all scripts working properly, run z_batch_publish_analyses.m
%   to create html report.  customize by editing z_batch_list_to_publish.m
%
% - saved in results folder:
%   figures
%   html report with figures and stats, in "published_output"
%
%
% LaBGAS NOTES
%
% - script to be run from rootdir of superdataset for your study
% - DO NOT FORGET TO MAKE STUDY-SPECIFIC CHANGES INDICATED BELOW
%
%__________________________________________________________________________
%
% modified by: Lukas Van Oudenhove
% date:   Dartmouth, May, 2022
%
%__________________________________________________________________________
% @(#)% a_set_up_paths_always_run_first.m         v1.1
% last modified: 2022/09/02


%% RUN PREP AND FIRST LEVEL DESIGN SCRIPT
% -------------------------------------------------------------------------

% check whether LaBGAScore_prep_s0_define_directories has been run
% STUDY-SPECIFIC: replace LaBGAScore with study name in code below

if ~exist('rootdir','var')
    warning('\nrootdir variable not found in Matlab workspace, running ery_4b_prep_s0_define_directories before proceeding')
    ery_4b_prep_s0_define_directories;
    cd(rootdir);
else
    cd(rootdir);
end

% check whether LaBGAScore_firstlevel_s1_options_dsgn_struct.m has been run
% STUDY-SPECIFIC: replace LaBGAScore with study name and add model index in code below

if ~exist('DSGN','var')
    warning('\nDSGN variable not found in Matlab workspace, running ery_4b_firstlevel_m1m_s1_options_dsgn_struct.m before proceeding')
    ery_4b_firstlevel_m1_s1_options_dsgn_struct;
end

[~,modelname] = fileparts(DSGN.modeldir); 
modelname_second = 'model_1m_long_12hmp_can_ar1';


%% SET DEFAULT USER OPTIONS
% -------------------------------------------------------------------------

% STUDY-SPECIFIC: add study name and model name to script name

ery_4b_secondlevel_m1m_s1_a2_set_default_options;

    
%% MAKE SURE DEPENDENCIES ARE ON MATLAB PATH
% -------------------------------------------------------------------------

% check whether spm subdirs are on path, add if needed

spmcanonicaldir = fullfile(spmrootdir,'canonical');
    if sum(contains(matlabpath,spmcanonicaldir)) == 0
        addpath(spmcanonicaldir,'-end');
        warning('\nadding %s to end of Matlab path',spmcanonicaldir)
    end
spmconfigdir = fullfile(spmrootdir,'config');
    if sum(contains(matlabpath,spmconfigdir)) == 0
        addpath(spmconfigdir,'-end');
        warning('\nadding %s to end of Matlab path',spmconfigdir)
    end
spmmatlabbatchdir = fullfile(spmrootdir,'matlabbatch');
    if sum(contains(matlabpath,spmmatlabbatchdir)) == 0
        addpath(spmmatlabbatchdir,'-end');
        warning('\nadding %s to end of Matlab path',spmmatlabbatchdir)
    end
spmtoolboxdir = fullfile(spmrootdir,'toolbox');
    if sum(contains(matlabpath,spmtoolboxdir)) == 0
        addpath(spmtoolboxdir,'-end');
        warning('\nadding %s to end of Matlab path',spmtoolboxdir)
    end
    
% check whether CANlab Github repos are cloned and on Matlab path, clone and/or add if needed

  % CANLABCORE
    canlabcoredir = fullfile(githubrootdir,'CanlabCore');
        if ~isfolder(canlabcoredir) % canlabcore not yet cloned
          canlabcoreurl = "https://github.com/canlab/CanlabCore.git";
          canlabcoreclonecmd = ['git clone ' canlabcoreurl];
          cd(githubrootdir);
          [status,cmdout] = system(canlabcoreclonecmd);
          disp(cmdout);
              if status == -0
                  addpath(genpath(canlabcoredir,'-end'));
                  warning('\ngit succesfully cloned %s to %s and added repo to Matlab path',canlabcoreurl, canlabcoredir)
              else
                  error('\ncloning %s into %s failed, please try %s in linux terminal before proceeding, or use Gitkraken',canlabcoreurl,canlabcoredir,canlabcoreclonecmd)
              end
          cd(rootdir);
          clear status cmdout
        elseif ~exist('fmri_data.m','file') % canlabcore cloned but not yet on Matlab path
            addpath(genpath(canlabcoredir),'-end');
        end
        
  % CANLABPRIVATE
    canlabprivdir = fullfile(githubrootdir,'CanlabPrivate');
        if ~isfolder(canlabprivdir) % canlabprivate not yet cloned
          canlabprivurl = "https://github.com/canlab/CanlabPrivate.git";
          canlabprivclonecmd = ['git clone ' canlabprivurl];
          cd(githubrootdir);
          [status,cmdout] = system(canlabprivclonecmd);
          disp(cmdout);
              if status == -0
                  addpath(genpath(canlabprivdir,'-end'));
                  warning('\ngit succesfully cloned %s to %s and added repo to Matlab path',canlabprivurl, canlabprivdir)
              else
                  error('\ncloning %s into %s failed, please try %s in linux terminal before proceeding, or use Gitkraken',canlabprivurl,canlabprivdir,canlabprivclonecmd)
              end
          cd(rootdir);
          clear status cmdout
        elseif ~exist('power_calc.m','file') % canlabprivate cloned but not yet on Matlab path
            addpath(genpath(canlabprivdir),'-end');
        end
        
  % CANLAB HELP EXAMPLES (LaBGAS fork)
    canlabhelpdir = fullfile(githubrootdir,'CANlab_help_examples');
        if ~isfolder(canlabhelpdir) % CANlab_help_examples not yet cloned
          canlabhelpurl = "https://github.com/labgas/CANlab_help_examples.git";
          canlabhelpclonecmd = ['git clone ' canlabhelpurl];
          cd(githubrootdir);
          [status,cmdout] = system(canlabhelpclonecmd);
          disp(cmdout);
              if status == -0
                  addpath(genpath(canlabhelpdir,'-end'));
                  warning('\ngit succesfully cloned %s to %s and added repo to Matlab path',canlabhelpurl, canlabhelpdir)
              else
                  error('\ncloning %s into %s failed, please try %s in linux terminal before proceeding, or use Gitkraken',canlabhelpurl,canlabhelpdir,canlabhelpclonecmd)
              end
          cd(rootdir);
          clear status cmdout
        elseif ~exist('a0_begin_here_readme.m','file') % CANlab_help_examples cloned but not yet on Matlab path
            addpath(genpath(canlabhelpdir),'-end');
        end
        
  % CANLAB SINGLE TRIALS
        canlabsingletrialsdir = fullfile(githubrootdir,'canlab_single_trials');
        if ~isfolder(canlabsingletrialsdir) % canlab_single_trials not yet cloned
          canlabsingletrialsurl = "https://github.com/labgas/canlab_single_trials.git";
          canlabsingletrialsclonecmd = ['git clone ' canlabsingletrialsurl];
          cd(githubrootdir);
          [status,cmdout] = system(canlabsingletrialsclonecmd);
          disp(cmdout);
              if status == -0
                  addpath(genpath(canlabsingletrialsdir,'-end'));
                  warning('\ngit succesfully cloned %s to %s and added repo to Matlab path',canlabsingletrialsurl, canlabsingletrialsdir)
              else
                  error('\ncloning %s into %s failed, please try %s in linux terminal before proceeding, or use Gitkraken',canlabsingletrialsurl,canlabsingletrialsdir,canlabsingletrialsclonecmd)
              end
          cd(rootdir);
          clear status cmdout
        elseif ~exist('fmri_data_st.m','file') % canlab_single_trials cloned but not yet on Matlab path
            addpath(genpath(canlabsingletrialsdir),'-end');
        end

        
%% SET BASE DIRECTORY AND CREATE STANDARD SUBDIR STRUCTURE
% -------------------------------------------------------------------------

% Base directory for second level model

basedir = fullfile(rootdir,'secondlevel',modelname_second);

    if ~exist(basedir, 'dir')
        mkdir(basedir); 
    end

% cd(basedir);

% Standard subdirs

datadir = fullfile(rootdir,'firstlevel',modelname); %lukasvo76: contrary to the original CANlab script, we want to keep firstlevel data in the model-specific dir of the firstlevel subdataset
    if ~exist(datadir, 'dir')
        error('\nfirstleveldir for modelname %s does not exist, please check naming and consistency with %s',modelname_second, fullfile(rootdir,'firstlevel')) 
    end
maskdir = fullfile(basedir,'masks');
    if ~exist(maskdir, 'dir')
        mkdir(maskdir); 
    end
    addpath(genpath(maskdir),'-end');
scriptsdir = fullfile(codedir,'secondlevel',modelname_second); %lukasvo76: contrary to the original CANlab script, we want our scripts to live in the code subdataset
    if ~exist(scriptsdir, 'dir')
        mkdir(scriptsdir); 
    end
resultsdir = fullfile(basedir, 'results');
    if ~exist(resultsdir, 'dir')
        mkdir(resultsdir); 
    end
figsavedir = fullfile(resultsdir, 'figures');
    if ~exist(figsavedir, 'dir')
        mkdir(figsavedir); 
    end
notesdir = fullfile(resultsdir, 'notes');
    if ~exist(notesdir, 'dir')
        mkdir(notesdir); 
    end
htmlsavedir = fullfile(resultsdir,'html');
    if ~exist(htmlsavedir,'dir')
        mkdir(htmlsavedir);
    end

    
%% DEFINE HELPER FUNCTION CALLED BY LATER SCRIPTS
% -------------------------------------------------------------------------

dashes = '----------------------------------------------';
printstr = @(dashes) disp(dashes);
printhdr = @(str) fprintf('%s\n%s\n%s\n', dashes, str, dashes);