%% Copyright George Nelson 2020 %%
function [SampleName,Area,Temp,Data] = FileRead(FileName)

fileID = fopen(strcat('./Data/',FileName,'.dat'));

Header = textscan(fileID,'%s',15,'Delimiter','\n');

for jj = 1:length(Header{1,1})  % Pull out the sample temp and sampling rate
    if contains(lower(Header{1,1}{jj,1}),'temperature=')
        temp_string = strsplit(Header{1,1}{jj,1},'=');
        Temp = str2double(temp_string{1,2});
    elseif contains(lower(Header{1,1}{jj,1}),'area=')
        area_string = strsplit(Header{1,1}{jj,1},'=');
        Area = str2double(area_string{1,2});
    elseif contains(lower(Header{1,1}{jj,1}),'identifier=')
        rate_string = strsplit(Header{1,1}{jj,1},'=');
        SampleName = rate_string{1,2};
    end
end

Data = cell2mat(textscan(fileID,'%f64 %f64 %f64'));

fclose(fileID);
end

