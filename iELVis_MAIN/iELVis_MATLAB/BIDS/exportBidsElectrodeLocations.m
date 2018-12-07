subj='PT001';
rootDir='/Users/davidgroppe/Desktop/';
task='tactile';
%globalFsDir
fsDir=getFsurfSubDir();
elecReconPath=fullfile(fsDir,subj,'elec_recon');
sessionId=1;

% BIDS directories
taskDir=fullfile(rootDir,sprintf('%s_task',task));
[SUCCESS,MESSAGE,MESSAGEID] = mkdir(taskDir);
subDir=fullfile(taskDir,sprintf('sub-%s',subj));
[SUCCESS,MESSAGE,MESSAGEID] = mkdir(subDir);
ieegDir=fullfile(subDir,'ieeg');
[SUCCESS,MESSAGE,MESSAGEID] = mkdir(ieegDir);


%% Export neuroimaging TODO


%% Import electrode names, type, and hemisphere
% Electrode names
elecNamesFname=fullfile(elecReconPath,sprintf('%s.electrodeNames',subj));
elecNamesCsv=csv2Cell(elecNamesFname,' ',2);
nElec=size(elecNamesCsv,1);
elecNames=cell(nElec,1);
elecType=cell(nElec,1);
elecHem=cell(nElec,1);
for a=1:nElec,
    elecNames{a}=elecNamesCsv{a,1};
    elecType{a}=elecNamesCsv{a,2};
    elecHem{a}=elecNamesCsv{a,3};
end


%% Import electrode locations
coordTypes={'ct','inf','leptp','leptovox','pial','pialvox'};
nCoordSpaces=length(coordTypes);
for sLoop=1:1, %% ?? debuging
    %for sLoop=1:nCoordSpaces,
    ielvisPostfix=upper(coordTypes{sLoop});
    
    % Import coordinates
    xyzFname=fullfile(elecReconPath,sprintf('%s.%s',subj,ielvisPostfix));
    xyzCoordStr=csv2Cell(xyzFname,' ',2);
    if size(xyzCoordStr,1)~=nElec,
        error('# of electrodes in %s does not match that in %s\n',xyzFname,elecNamesFname);
    end
    % Convert coordinates from string to double
    xyzCoord=zeros(nElec,3);
    for a=1:nElec,
        for b=1:3,
            xyzCoord(a,b)=str2double(xyzCoordStr{a,b});
        end
    end
    
    %% Create channels.tsv file
    elecSpace=coordTypes{sLoop};
    % outFname=fullfile(ieegDir,sprintf('sub-%.2d_task-%s_run-%.2_channels.tsv', ...
    %     subId,task,runId));
    elecTsvFname=fullfile(ieegDir,sprintf('sub-%s_ses-%.2d_space-%s_electrodes.tsv', ...
        subj,sessionId,elecSpace));
    fid=fopen(elecTsvFname,'w');
    % Header
    fprintf(fid,'name\tx\ty\tz\tsize\ttype\tmanufacturer\n');
    % Elec info
    for eLoop=1:nElec,
        elecManufacturer='Unknown'; % TODO make it possible to import this from file
        elecSize=nan; % TODO make it possible to import this from file
        % TODO add hemisphere to this?
        switch elecType{eLoop}
            case 'D'
                thisElecType='depth';
            case 'G'
                thisElecType='grid';
            case 'S'
                thisElecType='strip';
            otherwise
                error('Unrecognized value of elecType: %s',elecType{eLoop});
        end
        fprintf(fid,'%d\t%f\t%f\t%f\t%f\t%s\t%s\n',elecNames{eLoop},xyzCoord(eLoop,1), ...
            xyzCoord(eLoop,2),xyzCoord(eLoop,3),elecSize,thisElecType,elecManufacturer);
    end
    fclose(fid);
    
    
    %% Create coordsystem.json file
    brainShiftCorrectMethod='??'; % TODO fix
    coordJsonFname=fullfile(ieegDir,sprintf('sub-%s_ses-%.2d_space-%s_coordsystem.json', ...
        subj,sessionId,elecSpace));
    anatFile='??'; % TODO fix
    fid=fopen(coordJsonFname,'w');
    fprintf(fid,'{\n');
    fprintf(fid,'"iEEGCoordinateSystem": "%s",\n',elecSpace);
    fprintf(fid,'"iEEGCoordinateUnits": "mm",\n');
    fprintf(fid,'"iEEGCoordinateProcessingDescripton": "%s",\n',brainShiftCorrectMethod);
    % TODO use fprintf(fid,"iEEGCoordinateProcessingReference": "Hermes et al., 2010 JNeuroMeth",
    fprintf(fid,'"IntendedFor": "%s"\n',anatFile);
    fprintf(fid,'}\n');
    fclose(fid);
    
end