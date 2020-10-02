function CV_FILE(sample,mfia,setTemperature,Biases,Caps,Res);
%TransientFile Saves transient data to LDLTS compatible iso file

fileName = strcat(sample.name,'_',num2str(setTemperature),'.dat');
fileDate = datestr(now,'dd-mm-yyyy  HH:MM');

status = mkdir(strcat(pwd,'\',sample.save_folder));
fid = fopen(fullfile(strcat(pwd,'\',sample.save_folder),fileName),'wt');
fprintf(fid, '[general]\n');
fprintf(fid, 'software=mfiaCV v1.0\n');
fprintf(fid, 'user=%s\n', sample.user);
fprintf(fid, 'date=%s\n', fileDate);  
fprintf(fid, 'comment=%s\n', sample.comment);
fprintf(fid, '[sample]\n');
fprintf(fid, 'Material=%s\n', sample.material);
fprintf(fid, 'Identifier=%s\n', sample.name);
fprintf(fid, 'area= %s\n', sample.area);
fprintf(fid, '[acquisition]\n');
fprintf(fid, 'Sampling Rate= %d\n', mfia.sample_rate);
fprintf(fid, 'Sampling Time= %d\n', mfia.sample_time);
fprintf(fid, 'Temperature= %f\n', setTemperature);
fprintf(fid, '[data]\n');
fprintf(fid, 'bias(V)\tcap(F)\tres(Ohm)\n');
for i=1:length(Biases)
    fprintf(fid, '%e\t%e\t%e\n', Biases(i),Caps(i),Res(i)');
end
fclose(fid);
end

