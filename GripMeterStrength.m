% This script detects maximal grip strength from time series of csv data which contains two columns: first column is time in second, second column is force
% the time points are not consistent and need interpolation to average all trials for each animal.

function GripMeterStrength()
%% clean the workspace
close all; clear all; clear
%set the working folder
dataFolder = 'E:\Raw data\Gip Strength';
%find csv file paths
dirContentRaw = dir(fullfile(dataFolder,'**/*.csv'));

%detect animal ID from file name: the first 8 characters
for i=1:size(dirContentRaw,1)
AnimalID(:,i)=string(dirContentRaw(i).name(1:8));
end
AnimalID=unique(AnimalID)';
clear i dataFolder

%% Initiate trial counts to for the second go through trial loop, the first loop is through animals
TrialCount=zeros(size(AnimalID));
%first loop through  each animal
for AnimalIndex=1:size(AnimalID)
%filter and find the current animal information    
SingleAnimalFilter = contains({dirContentRaw.name}',AnimalID(AnimalIndex));
CurrentAnimal = dirContentRaw(SingleAnimalFilter);
TrialCount(AnimalIndex) = length({CurrentAnimal.name}');
clear MatchID
for TrialIndex= 1:TrialCount(AnimalIndex)
%get current animal file path   
CurrentAnimalFilePath=fullfile(CurrentAnimal(TrialIndex).folder,CurrentAnimal(TrialIndex).name);
%load data from csv
GripStrengthData=table2array(readtable(CurrentAnimalFilePath));
%save the first column time points
TimeColumn=GripStrengthData(:,1);
%remove duplicate time points
[TimeColumn, index] = unique(TimeColumn); 
GripStrengthData=GripStrengthData(index,:);
%find time-coordinate for peak grip strength
[indx,~]=find(GripStrengthData(:,2)==max(GripStrengthData(:,2)));
% set time to 0 for peak grip strength to align different trials for each animal
TimeColumn= TimeColumn-TimeColumn(indx(1));

%set x range for interopalation since the time step are not consistent
%across trials
InterpolationXrange = linspace(-300, 1000, 200);
%save the force data for each trial
InterpolatedGripStrengthData(:,TrialIndex) = interp1(TimeColumn, GripStrengthData(:,2), InterpolationXrange);
%save the maxiaml force data from raw data for each trial 
maxstrengthRaw(TrialIndex)=max(GripStrengthData(:,2));
%save the maxiaml force data from interpolated data for each trial and from each
%animal
maxstrengthInterpolated(AnimalIndex,TrialIndex)=max(InterpolatedGripStrengthData(:,TrialIndex));
end
%average the trial data for maximal grip force from raw csv data
maxstrengthRaw_avg(AnimalIndex)=mean(maxstrengthRaw);

%average the trial data for maximal grip force from interpolated force,
%single trial data were preserved to find outliers for interpolated maximal
%grip strength
maxstrengthInterpolated(maxstrengthInterpolated==0) = NaN;
maxstrengthInterpolated_avg(AnimalIndex)=nanmean(maxstrengthInterpolated(AnimalIndex,:));

%plot all interpolated trace from each trial in each figure, one figure for
%each animal
figure, plot(InterpolationXrange,InterpolatedGripStrengthData);
xlabel('time (s)')
ylabel('grip strength (g)')
title(AnimalID(AnimalIndex))
% check whether interpolated trace matches raw trace in their shape, this
% is for single trial only and used to compare with the current interpolated trace
% hold on, plot(GripStrengthData(:,1),GripStrengthData(:,2));hold off
clear maxstrengthRaw indx indy TrialIndex index GripStrengthData TimeColumn
%generate average trial trace for each animal
GripTrialAvg(:,AnimalIndex)=mean(InterpolatedGripStrengthData,2);
clear InterpolatedGripStrengthData
end
clear AnimalIndex CurrentAnimalFilePath dirContentRaw SingleAnimal TrialCount 
%% plotting the trial average data and compare across animals
figure
plot(InterpolationXrange,GripTrialAvg); 
xlim([-200,300]);
legend(AnimalID);
xlabel('time (s)')
ylabel('grip strength (g)')
title('trial average for each animal')
%compare whether the maximal grip strength from raw data matches with
%interpolated data, raw data were used for exporting and statistical
%analysis in R or Prism
figure
scatter(maxstrengthRaw_avg,maxstrengthInterpolated_avg)
xlabel('maximal force trial average from csv file')
ylabel('maximal force trial average from interpolated data')
title('how good is the interpolation')
% join animal id with maximal grip strength from csv data
animalJoint=[AnimalID,maxstrengthRaw_avg'];
clear AnimalID
end