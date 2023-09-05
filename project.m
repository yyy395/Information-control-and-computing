clc;
clear;
close all;
fs = 8000; %采样频率
nbits=16; %量化位数
n_channel=1; %声道数
ts=2; %采样时间
%录制音频
% R = audiorecorder(fs, nbits ,n_channel) ;
% disp('Start speaking.')
% recordblocking(R,ts);
% disp('End of Recording.');
% command = getaudiodata(R);
% audiowrite('command.flac', command, fs);
%读取音频
[y,f]=audioread('cmd.flac');
y=y(8001:end); %取后一秒的音频
fy=fft(y);
fy1=abs(fy);
len=length(y);
t=(0:len-1)/f;
f1 = 0:f/2-1;
f2=0:f-1;
figure(1);
subplot(1,2,1);
plot(t,y);
title('语音信号时域图');
xlabel('time/s');
ylabel('amplitude');
subplot(1,2,2);
plot(f1,fy1(1:f/2));
title('语音信号频域图');
xlabel('f/Hz');
ylabel('amplitude');
%量化编码,采用霍夫曼编码
q=(1-(-1))/2^nbits; %量化器分辨率
y_quantize=floor((y+1)/q);  %量化得到的信号
temp=tabulate(y_quantize);
number_temp=temp(:,2);
[r,c]=size(temp);
index=1;
symbol=0;
percent=0;
for i = 1:r %计算每个码字出现的频率
    if(number_temp(i)~=0)
        symbol(index)=temp(i,1);
        percent(index)=temp(i,3);
        index=index+1;
    end
end
percent=percent/100;
[dict, avglen] = huffmandict(symbol, percent);
y_encode=huffmanenco(y_quantize,dict); %霍夫曼编码
for i = 1:length(symbol)
    fprintf('%d : ', symbol(i));
    fprintf('%d ', dict{i,2});
    fprintf('\n');
end
fprintf('平均码长 : %f\n', avglen );
fprintf('信源熵 : %f\n', sum(percent.*(-log2(percent))) );
fprintf('编码效率 : %f\n', sum(percent.*(-log2(percent))/avglen) );
len_b=length(y_quantize)*nbits;
len_e=length(y_encode);
fprintf('编码前字符串总长度 : %d\n', len_b);
fprintf('编码后字符串二进制总长度 : %d\n', len_e);
fprintf('压缩率 : %f\n', len_b/len_e);
%信道编码，采用曼彻斯特编码
y_channel_MC=zeros(1,2.*length(y_encode));
for i=2:2:2*length(y_encode)
    if y_encode(i./2)==1 %“1”用“10”编码
        y_channel_MC(i-1)=1;
        y_channel_MC(i)=0;
    else if y_encode(i./2)==0 %“0”用“01”编码
            y_channel_MC(i-1)=0;
            y_channel_MC(i)=1;
        end
    end
end
%BPSK调制，加入噪声，模仿噪声信道传输
snr=10;
y_bpsk_out = pskmod(y_channel_MC,2);    %BPSK调制
y_awgn_out = awgn(y_bpsk_out, snr);  %加入高斯白噪声
scatterplot(y_bpsk_out)				%绘制发送信号的星座图
scatterplot(y_awgn_out)				%绘制接收信号的星座图
%解调
y_dm=pskdemod(y_awgn_out,2);
y_dm=double(y_dm>0.5);
[m_err, m_ber] = biterr(y_dm, y_channel_MC);
fprintf('出错数 : %d\n', m_err);
fprintf('误码率 : %f\n', m_ber);
%信道译码
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
fprintf('出错数 : %d\n', c_err);
fprintf('误码率 : %f\n', c_ber);
%信源译码
y_decode=huffmandeco(y_dechannel,dict);
[y_err, y_ber] = biterr(y_dechannel, y_encode.');
fprintf('出错数 : %d\n', y_err);
fprintf('误码率 : %f\n', y_ber);
%信号重建
y_restore=q*y_decode-1;
fprintf('均方误差为 : %f\n', mse(y_restore-y.'));
sound(y_restore,fs); %播放重建的信号
%语音识别
load('commandNet.mat','trainedNet'); %导入预训练模型
auditorySpect = extractAuditorySpectrogram(y_restore.',fs); %提取声音特征信息
command_v = classify(trainedNet,auditorySpect.'); %语音识别
disp(command_v)
figure(5);
subplot(1,2,1);
plot(y_restore, 'b');
axis tight;
title(string(command_v));
subplot(1,2,2);
pcolor(auditorySpect)
shading flat
%控制系统对指令进行输出
control=control(command_v);
disp(control)