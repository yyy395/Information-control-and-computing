clc;
clear;
close all;
fs = 8000; %����Ƶ��
nbits=16; %����λ��
n_channel=1; %������
ts=2; %����ʱ��
%¼����Ƶ
% R = audiorecorder(fs, nbits ,n_channel) ;
% disp('Start speaking.')
% recordblocking(R,ts);
% disp('End of Recording.');
% command = getaudiodata(R);
% audiowrite('command.flac', command, fs);
%��ȡ��Ƶ
[y,f]=audioread('cmd.flac');
y=y(8001:end); %ȡ��һ�����Ƶ
fy=fft(y);
fy1=abs(fy);
len=length(y);
t=(0:len-1)/f;
f1 = 0:f/2-1;
f2=0:f-1;
figure(1);
subplot(1,2,1);
plot(t,y);
title('�����ź�ʱ��ͼ');
xlabel('time/s');
ylabel('amplitude');
subplot(1,2,2);
plot(f1,fy1(1:f/2));
title('�����ź�Ƶ��ͼ');
xlabel('f/Hz');
ylabel('amplitude');
%��������,���û���������
q=(1-(-1))/2^nbits; %�������ֱ���
y_quantize=floor((y+1)/q);  %�����õ����ź�
temp=tabulate(y_quantize);
number_temp=temp(:,2);
[r,c]=size(temp);
index=1;
symbol=0;
percent=0;
for i = 1:r %����ÿ�����ֳ��ֵ�Ƶ��
    if(number_temp(i)~=0)
        symbol(index)=temp(i,1);
        percent(index)=temp(i,3);
        index=index+1;
    end
end
percent=percent/100;
[dict, avglen] = huffmandict(symbol, percent);
y_encode=huffmanenco(y_quantize,dict); %����������
for i = 1:length(symbol)
    fprintf('%d : ', symbol(i));
    fprintf('%d ', dict{i,2});
    fprintf('\n');
end
fprintf('ƽ���볤 : %f\n', avglen );
fprintf('��Դ�� : %f\n', sum(percent.*(-log2(percent))) );
fprintf('����Ч�� : %f\n', sum(percent.*(-log2(percent))/avglen) );
len_b=length(y_quantize)*nbits;
len_e=length(y_encode);
fprintf('����ǰ�ַ����ܳ��� : %d\n', len_b);
fprintf('������ַ����������ܳ��� : %d\n', len_e);
fprintf('ѹ���� : %f\n', len_b/len_e);
%�ŵ����룬��������˹�ر���
y_channel_MC=zeros(1,2.*length(y_encode));
for i=2:2:2*length(y_encode)
    if y_encode(i./2)==1 %��1���á�10������
        y_channel_MC(i-1)=1;
        y_channel_MC(i)=0;
    else if y_encode(i./2)==0 %��0���á�01������
            y_channel_MC(i-1)=0;
            y_channel_MC(i)=1;
        end
    end
end
%BPSK���ƣ�����������ģ�������ŵ�����
snr=10;
y_bpsk_out = pskmod(y_channel_MC,2);    %BPSK����
y_awgn_out = awgn(y_bpsk_out, snr);  %�����˹������
scatterplot(y_bpsk_out)				%���Ʒ����źŵ�����ͼ
scatterplot(y_awgn_out)				%���ƽ����źŵ�����ͼ
%���
y_dm=pskdemod(y_awgn_out,2);
y_dm=double(y_dm>0.5);
[m_err, m_ber] = biterr(y_dm, y_channel_MC);
fprintf('������ : %d\n', m_err);
fprintf('������ : %f\n', m_ber);
%�ŵ�����
y_dechannel=zeros(1,length(y_channel_MC)/2);
for i = 2:2:length(y_channel_MC)
    if(y_channel_MC(i-1)==1&&y_channel_MC(i)==0)
        y_dechannel(i/2)=1;
    else if(y_channel_MC(i-1)==0&&y_channel_MC(i)==1)
            y_dechannel(i/2)=0;
        end
    end
end
[c_err, c_ber] = biterr(y_dechannel, y_encode.');
fprintf('������ : %d\n', c_err);
fprintf('������ : %f\n', c_ber);
%��Դ����
y_decode=huffmandeco(y_dechannel,dict);
[y_err, y_ber] = biterr(y_dechannel, y_encode.');
fprintf('������ : %d\n', y_err);
fprintf('������ : %f\n', y_ber);
%�ź��ؽ�
y_restore=q*y_decode-1;
fprintf('�������Ϊ : %f\n', mse(y_restore-y.'));
sound(y_restore,fs); %�����ؽ����ź�
%����ʶ��
load('commandNet.mat','trainedNet'); %����Ԥѵ��ģ��
auditorySpect = extractAuditorySpectrogram(y_restore.',fs); %��ȡ����������Ϣ
command_v = classify(trainedNet,auditorySpect.'); %����ʶ��
disp(command_v)
figure(5);
subplot(1,2,1);
plot(y_restore, 'b');
axis tight;
title(string(command_v));
subplot(1,2,2);
pcolor(auditorySpect)
shading flat
%����ϵͳ��ָ��������
control=control(command_v);
disp(control)