function control=control(x)
    x=string(x);
    switch x
        case 'go'
            control='С��ǰ��';
        case 'right'
            control='С����ת';
        case 'up'
            control='С��̧��ǰ��';
        case 'left'
            control='С����ת';
        case 'down'
            control='С������ǰ��';
        case 'stop'
            control='С��ֹͣ';
        case 'unknown'
            control='The command is unknown.';
        case 'background'
            control='The command is background noise.';
        case 'on'
            control='The command is not right';
        case 'off'
            control='The command is not right';
        case 'yes'
            control='The command is not right';
        case 'no'
            control='The command is not right';
    end
end